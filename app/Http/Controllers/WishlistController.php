<?php

namespace App\Http\Controllers;

use App\Models\WishlistItem;
use App\Models\CartItem;
use App\Models\Item;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\Auth;

class WishlistController extends Controller
{
    public function index(Request $request)
    {
        $userId = Auth::id();
        if (!$userId) {
            return redirect()->route('login')->with('message', 'يرجى تسجيل الدخول لعرض قائمة المفضلة.');
        }

        $wishlistItems = WishlistItem::where('user_id', $userId)
            ->with(['item.category', 'item.storeItems'])
            ->latest()
            ->get();

        $wishlistItems->each(function ($wi) {
            if ($wi->item) {
                $wi->item->append(['effective_price', 'total_stock']);
            }
        });

        $cartCount = CartItem::where('user_id', $userId)->sum('quantity');
        $wishlistIds = $wishlistItems->pluck('item_id')->toArray();

        return Inertia::render('Store/Wishlist', [
            'wishlistItems' => $wishlistItems,
            'storeContext' => [
                'cartCount' => (int)$cartCount,
                'wishlistIds' => $wishlistIds,
            ],
        ]);
    }

    public function toggle(Request $request)
    {
        $validated = $request->validate([
            'item_id' => 'required|exists:items,id',
        ]);

        $userId = Auth::id();
        if (!$userId) {
            if ($request->wantsJson()) {
                return response()->json(['requiresAuth' => true, 'redirect' => route('login')], 401);
            }
            return redirect()->route('login')->with('message', 'يرجى تسجيل الدخول لإضافة المنتجات إلى المفضلة.');
        }

        $existing = WishlistItem::where('user_id', $userId)
            ->where('item_id', $validated['item_id'])
            ->first();

        $added = false;
        if ($existing) {
            $existing->delete();
            $message = 'تمت إزالة المنتج من المفضلة.';
        } else {
            WishlistItem::create([
                'user_id' => $userId,
                'item_id' => $validated['item_id'],
            ]);
            $added = true;
            $message = 'تمت إضافة المنتج إلى المفضلة.';
        }

        if ($request->wantsJson()) {
            $wishlistIds = WishlistItem::where('user_id', $userId)->pluck('item_id')->toArray();
            return response()->json([
                'success' => true,
                'added' => $added,
                'message' => $message,
                'wishlistIds' => $wishlistIds,
            ]);
        }

        return back()->with('success', $message);
    }

    public function moveToCart(Request $request, $id)
    {
        $userId = Auth::id();
        if (!$userId) {
            return redirect()->route('login');
        }

        $wishlistItem = WishlistItem::where('user_id', $userId)->findOrFail($id);

        $cartItem = CartItem::where('user_id', $userId)
            ->where('item_id', $wishlistItem->item_id)
            ->first();

        if ($cartItem) {
            $cartItem->quantity += 1;
            $cartItem->save();
        } else {
            CartItem::create([
                'user_id' => $userId,
                'item_id' => $wishlistItem->item_id,
                'quantity' => 1,
            ]);
        }

        $wishlistItem->delete();

        return back()->with('success', 'تم نقل المنتج إلى سلة المشتريات.');
    }

    public function destroy(Request $request, $id)
    {
        $userId = Auth::id();
        if (!$userId) {
            return redirect()->route('login');
        }

        $wishlistItem = WishlistItem::where('user_id', $userId)->findOrFail($id);
        $wishlistItem->delete();

        return back()->with('success', 'تمت إزالة المنتج من المفضلة.');
    }
}
