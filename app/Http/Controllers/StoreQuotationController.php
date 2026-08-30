<?php

namespace App\Http\Controllers;

use App\Models\Quotation;
use App\Models\QuotationLine;
use App\Models\Item;
use App\Models\CartItem;
use App\Models\Party;
use App\Models\Account;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;

class StoreQuotationController extends Controller
{
    /**
     * Generate formal ERP Price Quotation from Customer Shopping Cart.
     */
    public function generateFromCart(Request $request)
    {
        $userId = Auth::id();
        $sessionId = $request->session()->getId();

        $cartQuery = CartItem::with('item');
        if ($userId) {
            $cartQuery->where('user_id', $userId);
        } else {
            $cartQuery->where('session_id', $sessionId);
        }
        $cartItems = $cartQuery->get();

        if ($cartItems->isEmpty()) {
            return redirect()->route('cart.index')->with('error', 'السلة فارغة. يرجى إضافة منتجات أولاً لطلب عرض سعر رسمي.');
        }

        $user = Auth::user();
        $party = null;

        if ($user) {
            $party = $user->party;
        }

        if (!$party) {
            $party = Party::firstOrCreate(
                ['name' => ($user?->name ?? 'عميل تجاري / زبون متجر')],
                [
                    'type' => 'customer',
                    'phone' => $user?->phone ?? '0599000000',
                    'address' => $user?->address ?? 'فلسطين',
                ]
            );
        }

        $quotationNumber = 'QUOT-' . date('Ymd') . '-' . rand(1000, 9999);
        $totalAmount = 0;

        foreach ($cartItems as $ci) {
            $price = $ci->item?->effective_price ?? 0;
            $totalAmount += ($price * $ci->quantity);
        }

        $quotation = Quotation::create([
            'quotation_number' => $quotationNumber,
            'party_id' => $party->id,
            'store_id' => 1,
            'date' => now()->toDateString(),
            'expiry_date' => now()->addDays(15)->toDateString(),
            'status' => 'draft',
            'total_amount' => $totalAmount,
            'tax_amount' => 0,
            'discount_amount' => 0,
            'notes' => 'عرض سعر رسمي معتمد صادر من متجر رنتيسي الإلكتروني ERP. صالح لمدة 15 يوماً من تاريخ الإصدار.',
        ]);

        foreach ($cartItems as $ci) {
            if ($ci->item) {
                QuotationLine::create([
                    'quotation_id' => $quotation->id,
                    'item_id' => $ci->item->id,
                    'quantity' => $ci->quantity,
                    'unit_price' => $ci->item->effective_price,
                    'total' => $ci->item->effective_price * $ci->quantity,
                ]);
            }
        }

        return redirect()->route('store.quotation.show', $quotation->id);
    }

    /**
     * Generate formal Quotation for a single product.
     */
    public function generateFromProduct(Request $request, $id)
    {
        $item = Item::findOrFail($id);
        $qty = max(1, (int)$request->input('quantity', 1));
        $user = Auth::user();

        $party = $user?->party;
        if (!$party) {
            $party = Party::firstOrCreate(
                ['name' => ($user?->name ?? 'عميل تجاري / زبون متجر')],
                [
                    'type' => 'customer',
                    'phone' => $user?->phone ?? '0599000000',
                    'address' => $user?->address ?? 'فلسطين',
                ]
            );
        }

        $quotationNumber = 'QUOT-' . date('Ymd') . '-' . rand(1000, 9999);
        $totalAmount = $item->effective_price * $qty;

        $quotation = Quotation::create([
            'quotation_number' => $quotationNumber,
            'party_id' => $party->id,
            'store_id' => 1,
            'date' => now()->toDateString(),
            'expiry_date' => now()->addDays(15)->toDateString(),
            'status' => 'draft',
            'total_amount' => $totalAmount,
            'tax_amount' => 0,
            'discount_amount' => 0,
            'notes' => "عرض سعر رسمي للمنتج: {$item->name}. صالح لمدة 15 يوماً.",
        ]);

        QuotationLine::create([
            'quotation_id' => $quotation->id,
            'item_id' => $item->id,
            'quantity' => $qty,
            'unit_price' => $item->effective_price,
            'total' => $totalAmount,
        ]);

        return redirect()->route('store.quotation.show', $quotation->id);
    }

    /**
     * Show / Print Official Quotation.
     */
    public function show($id)
    {
        $quotation = Quotation::with(['party', 'store', 'lines.item'])
            ->findOrFail($id);

        return Inertia::render('Store/QuotationPrint', [
            'quotation' => $quotation,
        ]);
    }
}
