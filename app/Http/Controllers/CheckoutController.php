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

        $shippingFee = $subtotal > 200 ? 0 : 20;
        $total = $subtotal + $shippingFee;

        return Inertia::render('Store/Checkout', [
            'cartItems' => $cartItems,
            'summary' => [
                'subtotal' => round($subtotal, 2),
                'shippingFee' => round($shippingFee, 2),
                'total' => round($total, 2),
                'itemsCount' => $cartItems->sum('quantity'),
            ],
            'customer' => [
                'name' => $user?->name ?? '',
                'email' => $user?->email ?? '',
                'phone' => $user?->phone ?? '',
                'address' => $user?->address ?? '',
                'city' => $user?->city ?? 'غزة',
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
            'payment_method' => 'required|in:cod,card,bank_transfer',
            'notes' => 'nullable|string|max:1000',
        ]);

        $user = Auth::user();
        $sessionId = $request->session()->getId();

        $cartQuery = $user ? CartItem::where('user_id', $user->id) : CartItem::where('session_id', $sessionId);
        $cartItems = $cartQuery->with('item')->get();

        if ($cartItems->isEmpty()) {
            return redirect()->route('store.shop')->with('error', 'السلة فارغة.');
        }

        return DB::transaction(function () use ($validated, $user, $sessionId, $cartItems) {
            // 1. Ensure or link customer Party in accounting system
            $party = null;
            if ($user && $user->party_id) {
                $party = Party::find($user->party_id);
            }

            if (!$party) {
                // Find Accounts Receivable (1103)
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

            // 3. Calculate order sums & Loyalty Points Discount
            $subtotal = 0;
            foreach ($cartItems as $ci) {
                $price = $ci->item ? $ci->item->effective_price : 0;
                $subtotal += $price * $ci->quantity;
            }
            $shippingFee = $subtotal > 200 ? 0 : 20;

            // Loyalty Points Redemption
            $pointsToRedeem = 0;
            $cashbackDiscount = 0;
            if ($user && $request->filled('redeem_points') && $request->boolean('redeem_points')) {
                $availablePoints = (int)($user->points_balance ?? 0);
                // Can redeem up to 50% of subtotal (10 points = 1 ILS)
                $maxRedeemableILS = $subtotal * 0.5;
                $maxRedeemablePoints = (int)($maxRedeemableILS * 10);
                $pointsToRedeem = min($availablePoints, $maxRedeemablePoints);
                if ($pointsToRedeem > 0) {
                    $cashbackDiscount = round($pointsToRedeem / 10, 2);
                }
            }

            $totalAmount = max(0, $subtotal + $shippingFee - $cashbackDiscount);

            // Calculate new points earned on this purchase (1 point per 10 ILS spent)
            $pointsEarned = (int)floor($totalAmount / 10);

            // 4. Create Accounting Sales Invoice
            $invoice = Invoice::create([
                'type' => 'sale',
                'date' => now()->toDateString(),
                'party_id' => $party->id,
                'store_id' => $store->id,
                'notes' => 'طلب إلكتروني من المتجر - العميل: ' . $validated['name'] . ($cashbackDiscount > 0 ? " (تم تطبيق خصم كاش باك {$cashbackDiscount} ₪)" : ''),
            ]);

            // 5. Create Order
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
                'payment_method' => $validated['payment_method'],
                'payment_status' => $validated['payment_method'] === 'card' ? 'paid' : 'unpaid',
                'shipping_name' => $validated['name'],
                'shipping_phone' => $validated['phone'],
                'shipping_address' => $validated['address'],
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
