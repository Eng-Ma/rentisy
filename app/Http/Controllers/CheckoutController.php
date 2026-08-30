<?php

namespace App\Http\Controllers;

use App\Models\CartItem;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Invoice;
use App\Models\InvoiceLine;
use App\Models\Party;
use App\Models\Store;
use App\Models\StoreItem;
use App\Models\Account;
use App\Models\User;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CheckoutController extends Controller
{
    public function index(Request $request)
    {
        $user = Auth::user();
        $sessionId = $request->session()->getId();

        $cartQuery = $user ? CartItem::where('user_id', $user->id) : CartItem::where('session_id', $sessionId);
        $cartItems = $cartQuery->with(['item.category', 'item.storeItems'])->get();

        if ($cartItems->isEmpty()) {
            return redirect()->route('store.shop')->with('message', 'سلة المشتريات فارغة، تصفح المنتجات وأضف ما يعجبك.');
        }

        $cartItems->each(function ($ci) {
            if ($ci->item) {
                $ci->item->append(['effective_price', 'total_stock']);
            }
        });

        $subtotal = $cartItems->sum(function ($ci) {
            return $ci->item ? $ci->item->effective_price * $ci->quantity : 0;
        });

        $pointsEligibleSubtotal = $cartItems->sum(function ($ci) {
            return ($ci->item && $ci->item->allows_points !== false) ? $ci->item->effective_price * $ci->quantity : 0;
        });

        $deliveryZones = \App\Models\DeliveryZone::where('is_active', true)
            ->where('is_approved', true)
            ->orderBy('city')
            ->orderBy('delivery_fee')
            ->get();

        $transferMethods = \App\Models\TransferMethod::active()->get();

        $userSuggestionsCount = $user ? \App\Models\DeliveryZone::where('suggested_by_user_id', $user->id)->count() : 0;

        $defaultZone = $deliveryZones->first();
        $defaultShippingFee = $defaultZone ? $defaultZone->delivery_fee : ($subtotal > 200 ? 0 : 20);
        $total = $subtotal + $defaultShippingFee;

        return Inertia::render('Store/Checkout', [
            'cartItems' => $cartItems,
            'deliveryZones' => $deliveryZones,
            'transferMethods' => $transferMethods,
            'remainingSuggestions' => max(0, 2 - $userSuggestionsCount),
            'summary' => [
                'subtotal' => round($subtotal, 2),
                'pointsEligibleSubtotal' => round($pointsEligibleSubtotal, 2),
                'maxPointsDiscount' => round($pointsEligibleSubtotal * 0.30, 2),
                'shippingFee' => round($defaultShippingFee, 2),
                'total' => round($total, 2),
                'itemsCount' => $cartItems->sum('quantity'),
            ],
            'customer' => [
                'name' => $user?->name ?? '',
                'email' => $user?->email ?? '',
                'phone' => $user?->phone ?? '',
                'address' => $user?->address ?? '',
                'city' => $user?->city ?? 'غزة',
                'points_balance' => (int)($user?->points_balance ?? 0),
            ],
            'storeContext' => [
                'cartCount' => (int)$cartItems->sum('quantity'),
                'wishlistIds' => $user ? $user->wishlistItems()->pluck('item_id')->toArray() : [],
            ],
        ]);
    }

    public function process(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255',
            'phone' => 'required|string|max:50',
            'address' => 'required|string|max:500',
            'city' => 'nullable|string|max:100',
            'delivery_type' => 'required|in:delivery,pickup',
            'delivery_zone_id' => 'nullable|exists:delivery_zones,id',
            'transfer_method_id' => 'required|exists:transfer_methods,id',
            'payment_receipt' => 'required|file|image|max:10240',
            'notes' => 'nullable|string|max:1000',
        ], [
            'transfer_method_id.required' => 'يرجى اختيار طريقة وحساب التحويل المالي.',
            'payment_receipt.required' => 'يرجى إرفاق سكرين شوت أو صورة إشعار التحويل البنكي/المحفظة لتأكيد طلبك.',
        ]);

        $user = Auth::user();
        $sessionId = $request->session()->getId();

        $cartQuery = $user ? CartItem::where('user_id', $user->id) : CartItem::where('session_id', $sessionId);
        $cartItems = $cartQuery->with('item')->get();

        if ($cartItems->isEmpty()) {
            return redirect()->route('store.shop')->with('error', 'السلة فارغة.');
        }

        // Handle Payment Screenshot Upload
        $receiptUrl = null;
        if ($request->hasFile('payment_receipt')) {
            $path = $request->file('payment_receipt')->store('payment_receipts', 'public');
            $receiptUrl = '/storage/' . $path;
        }

        return DB::transaction(function () use ($validated, $user, $sessionId, $cartItems, $request, $receiptUrl) {
            // 1. Ensure or link customer Party in accounting system
            $party = null;
            if ($user && $user->party_id) {
                $party = Party::find($user->party_id);
            }

            if (!$party) {
                $arAccount = Account::where('code', '1103')->orWhere('name', 'like', '%عملاء%')->orWhere('name', 'like', '%الذمم المدينة%')->first();

                $party = Party::create([
                    'type' => 'customer',
                    'name' => $validated['name'],
                    'phone' => $validated['phone'],
                    'address' => ($validated['city'] ? $validated['city'] . ' - ' : '') . $validated['address'],
                    'account_id' => $arAccount?->id,
                ]);

                if ($user) {
                    $user->party_id = $party->id;
                    $user->phone = $validated['phone'];
                    $user->address = $validated['address'];
                    $user->city = $validated['city'] ?? $user->city;
                    $user->save();
                }
            }

            // 2. Resolve default active Store
            $store = Store::where('is_active', true)->first();
            if (!$store) {
                $store = Store::firstOrCreate(
                    ['id' => 1],
                    ['name' => 'المستودع الرئيسي', 'code' => 'MAIN-01', 'is_active' => true]
                );
            }

            // 3. Calculate order sums & Delivery Fee based on Zone or Pickup
            $shippingFee = 0.00;
            $zoneId = null;

            if ($validated['delivery_type'] === 'pickup') {
                $shippingFee = 0.00;
            } elseif (!empty($validated['delivery_zone_id'])) {
                $zone = \App\Models\DeliveryZone::find($validated['delivery_zone_id']);
                if ($zone) {
                    $shippingFee = (float)$zone->delivery_fee;
                    $zoneId = $zone->id;
                } else {
                    $shippingFee = 20;
                }
            } else {
                $shippingFee = 20;
            }

            // Calculate Subtotal and Points-Eligible Subtotal
            $subtotal = 0;
            $pointsEligibleSubtotal = 0;
            foreach ($cartItems as $ci) {
                $price = $ci->item ? $ci->item->effective_price : 0;
                $lineTotal = $price * $ci->quantity;
                $subtotal += $lineTotal;
                if ($ci->item && $ci->item->allows_points !== false) {
                    $pointsEligibleSubtotal += $lineTotal;
                }
            }

            // Loyalty Points Redemption (Capped at 30% of Points-Eligible Items)
            $pointsToRedeem = 0;
            $cashbackDiscount = 0;
            if ($user && $request->filled('redeem_points') && $request->boolean('redeem_points')) {
                $availablePoints = (int)($user->points_balance ?? 0);
                $maxRedeemableILS = $pointsEligibleSubtotal * 0.30; // Max 30% discount!
                $maxRedeemablePoints = (int)($maxRedeemableILS * 10);
                $pointsToRedeem = min($availablePoints, $maxRedeemablePoints);
                if ($pointsToRedeem > 0) {
                    $cashbackDiscount = round($pointsToRedeem / 10, 2);
                }
            }

            $totalAmount = max(0, $subtotal + $shippingFee - $cashbackDiscount);
            // Points earned only on points-eligible items net amount
            $pointsEarned = (int)floor(max(0, $pointsEligibleSubtotal - $cashbackDiscount) / 10);

            // 4. Create Accounting Sales Invoice
            $invoice = Invoice::create([
                'type' => 'sale',
                'date' => now()->toDateString(),
                'party_id' => $party->id,
                'store_id' => $store->id,
                'notes' => 'طلب إلكتروني من المتجر - العميل: ' . $validated['name'] . ($receiptUrl ? ' [تم إرفاق إشعار تحويل بنكي/محفظة]' : ''),
            ]);

            // 5. Create Order with Transfer Method and Payment Receipt
            $transferMethod = \App\Models\TransferMethod::find($validated['transfer_method_id']);
            $orderNumber = 'ORD-' . date('Ymd') . '-' . strtoupper(Str::random(5));
            $order = Order::create([
                'order_number' => $orderNumber,
                'user_id' => $user?->id,
                'party_id' => $party->id,
                'invoice_id' => $invoice->id,
                'status' => 'pending',
                'subtotal' => $subtotal,
                'discount_amount' => $cashbackDiscount,
                'points_earned' => $pointsEarned,
                'points_redeemed' => $pointsToRedeem,
                'cashback_discount' => $cashbackDiscount,
                'shipping_fee' => $shippingFee,
                'total_amount' => $totalAmount,
                'payment_method' => $transferMethod?->name ?? 'تحويل بنكي / محفظة',
                'transfer_method_id' => $transferMethod?->id,
                'transfer_method_name' => $transferMethod?->name,
                'payment_status' => 'unpaid', // Admin verifies transfer screenshot before setting to paid
                'payment_receipt_url' => $receiptUrl,
                'is_payment_verified' => false,
                'delivery_type' => $validated['delivery_type'],
                'delivery_zone_id' => $zoneId,
                'shipping_name' => $validated['name'],
                'shipping_phone' => $validated['phone'],
                'shipping_address' => $validated['delivery_type'] === 'pickup' ? 'استلام شخصي من المعرض / المستودع الرئيسي' : $validated['address'],
                'shipping_city' => $validated['city'] ?? '',
                'notes' => $validated['notes'] ?? null,
            ]);

            // 5.1 Update User Loyalty Points Balance and Log Transactions
            if ($user) {
                if ($pointsToRedeem > 0) {
                    $user->decrement('points_balance', $pointsToRedeem);
                    \App\Models\LoyaltyTransaction::create([
                        'user_id' => $user->id,
                        'points' => -$pointsToRedeem,
                        'type' => 'redeemed',
                        'description' => "استبدال {$pointsToRedeem} نقطة بخصم مالي {$cashbackDiscount} ₪ على الطلب #{$orderNumber}",
                        'order_id' => $order->id,
                    ]);
                }

                if ($pointsEarned > 0) {
                    $user->increment('points_balance', $pointsEarned);
                    \App\Models\LoyaltyTransaction::create([
                        'user_id' => $user->id,
                        'points' => $pointsEarned,
                        'type' => 'earned',
                        'description' => "كاش باك نقاط ولاء مكتسبة من الطلب #{$orderNumber}",
                        'order_id' => $order->id,
                    ]);
                }
            }

            // 6. Create Order Lines & Invoice Lines & Deduct Store Inventory
            foreach ($cartItems as $ci) {
                if (!$ci->item) continue;
                $unitPrice = $ci->item->effective_price;
                $lineTotal = $unitPrice * $ci->quantity;

                // Order item line
                OrderItem::create([
                    'order_id' => $order->id,
                    'item_id' => $ci->item_id,
                    'item_name' => $ci->item->name,
                    'quantity' => $ci->quantity,
                    'unit_price' => $unitPrice,
                    'total_price' => $lineTotal,
                ]);

                // Accounting Invoice Line
                InvoiceLine::create([
                    'invoice_id' => $invoice->id,
                    'item_id' => $ci->item_id,
                    'quantity' => $ci->quantity,
                    'unit_price' => $unitPrice,
                ]);

                // Deduct inventory from StoreItem
                $storeItem = StoreItem::firstOrCreate(
                    ['store_id' => $store->id, 'item_id' => $ci->item_id],
                    ['quantity' => 0]
                );
                $storeItem->decrement('quantity', $ci->quantity);
            }

            // 7. Clear Cart
            $cartQuery = $user ? CartItem::where('user_id', $user->id) : CartItem::where('session_id', $sessionId);
            $cartQuery->delete();

            // 8. Redirect
            if ($user) {
                return redirect()->route('customer.orders.show', $order->id)->with('success', 'تم استلام طلبك بنجاح وإنشاء فاتورة المبيعات في نظام المحاسبة!');
            }

            return redirect()->route('store.shop')->with('success', "تم استلام طلبك بنجاح برقم: {$orderNumber}. شكراً لتسوقك معنا!");
        });
    }
}
