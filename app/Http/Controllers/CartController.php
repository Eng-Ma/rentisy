<?php

namespace App\Http\Controllers;

use App\Models\CartItem;
use App\Models\Item;
use App\Models\WishlistItem;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\Auth;

class CartController extends Controller
{
    protected function getCartQuery(Request $request)
    {
        $userId = Auth::id();
        $sessionId = $request->session()->getId();

        if ($userId) {
            return CartItem::where('user_id', $userId);
        }

        return CartItem::where('session_id', $sessionId);
    }

    public function index(Request $request)
    {
        $userId = Auth::id();
        $wishlistIds = $userId ? WishlistItem::where('user_id', $userId)->pluck('item_id')->toArray() : [];

        $cartItems = $this->getCartQuery($request)
            ->with(['item.category', 'item.storeItems'])
            ->get();

        $cartItems->each(function ($cartItem) {
            if ($cartItem->item) {
                $cartItem->item->append(['effective_price', 'total_stock']);
            }
        });

        $subtotal = $cartItems->sum(function ($cartItem) {
            return $cartItem->item ? $cartItem->item->effective_price * $cartItem->quantity : 0;
        });

        $shippingFee = $subtotal > 200 || $subtotal == 0 ? 0 : 20; // Free shipping over 200
        $tax = $subtotal * 0.05; // 5% tax or 0
        $total = $subtotal + $shippingFee;

        return Inertia::render('Store/Cart', [
            'cartItems' => $cartItems,
            'summary' => [
                'subtotal' => round($subtotal, 2),
                'shippingFee' => round($shippingFee, 2),
                'tax' => round($tax, 2),
                'total' => round($total, 2),
                'itemsCount' => $cartItems->sum('quantity'),
            ],
            'storeContext' => [
                'cartCount' => (int)$cartItems->sum('quantity'),
                'wishlistIds' => $wishlistIds,
            ],
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'item_id' => 'required|exists:items,id',
            'quantity' => 'nullable|integer|min:1|max:100',
        ]);

        $userId = Auth::id();
        $sessionId = $request->session()->getId();
        $quantity = $validated['quantity'] ?? 1;

        $cartItem = $this->getCartQuery($request)
            ->where('item_id', $validated['item_id'])
            ->first();

        if ($cartItem) {
            $cartItem->quantity += $quantity;
            $cartItem->save();
        } else {
            CartItem::create([
                'user_id' => $userId,
                'session_id' => $userId ? null : $sessionId,
                'item_id' => $validated['item_id'],
                'quantity' => $quantity,
            ]);
        }

        if ($request->wantsJson()) {
            $count = $this->getCartQuery($request)->sum('quantity');
            return response()->json(['success' => true, 'cartCount' => $count]);
        }

        return back()->with('success', 'تمت إضافة المنتج إلى السلة بنجاح.');
    }

    public function update(Request $request, $id)
    {
        $validated = $request->validate([
            'quantity' => 'required|integer|min:1|max:100',
        ]);

        $cartItem = $this->getCartQuery($request)->findOrFail($id);
        $cartItem->update(['quantity' => $validated['quantity']]);

        return back()->with('success', 'تم تحديث كمية المنتج.');
    }

    public function destroy(Request $request, $id)
    {
        $cartItem = $this->getCartQuery($request)->findOrFail($id);
        $cartItem->delete();

        return back()->with('success', 'تم حذف المنتج من السلة.');
    }

    public function clear(Request $request)
    {
        $this->getCartQuery($request)->delete();

        return back()->with('success', 'تم تفريغ السلة.');
    }
}
