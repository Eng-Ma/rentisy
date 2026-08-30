<?php

namespace App\Http\Controllers;

use App\Models\Item;
use App\Models\Category;
use App\Models\CartItem;
use App\Models\WishlistItem;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\Auth;

class StorefrontController extends Controller
{
    /**
     * Get common store data like cart and wishlist items for current user/session.
     */
    protected function getStoreContext(Request $request)
    {
        $userId = Auth::id();
        $sessionId = $request->session()->getId();

        $cartCount = 0;
        $wishlistIds = [];

        if ($userId) {
            $cartCount = CartItem::where('user_id', $userId)->sum('quantity');
            $wishlistIds = WishlistItem::where('user_id', $userId)->pluck('item_id')->toArray();
        } else {
            $cartCount = CartItem::where('session_id', $sessionId)->sum('quantity');
        }

        return [
            'cartCount' => (int)$cartCount,
            'wishlistIds' => $wishlistIds,
        ];
    }

    /**
     * Store Landing Page
     */
    public function index(Request $request)
    {
        $context = $this->getStoreContext($request);

        $categories = Category::where('is_active', true)
            ->withCount(['items' => function ($q) {
                $q->where('is_active', true);
            }])
            ->get();

        $featuredItems = Item::where('is_active', true)
            ->where('is_featured', true)
            ->with(['category', 'storeItems'])
            ->take(8)
            ->get()
            ->append(['effective_price', 'total_stock']);

        $dealItems = Item::where('is_active', true)
            ->where('is_deal', true)
            ->with(['category', 'storeItems'])
            ->take(6)
            ->get()
            ->append(['effective_price', 'total_stock']);

        $newArrivals = Item::where('is_active', true)
            ->with(['category', 'storeItems'])
            ->latest()
            ->take(8)
            ->get()
            ->append(['effective_price', 'total_stock']);

        return Inertia::render('Store/Index', [
            'categories' => $categories,
            'featuredItems' => $featuredItems,
            'dealItems' => $dealItems,
            'newArrivals' => $newArrivals,
            'storeContext' => $context,
        ]);
    }

    /**
     * Product Catalog / Shop Page
     */
    public function shop(Request $request)
    {
        $context = $this->getStoreContext($request);

        $query = Item::where('is_active', true)->with(['category', 'storeItems']);

        // Filter by search
        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%")
                  ->orWhere('barcode', 'like', "%{$search}%");
            });
        }

        // Filter by category
        if ($request->filled('category_id')) {
            $query->where('category_id', $request->input('category_id'));
        }

        // Filter by price range
        if ($request->filled('min_price')) {
            $query->where('sales_price', '>=', (float)$request->input('min_price'));
        }
        if ($request->filled('max_price')) {
            $query->where('sales_price', '<=', (float)$request->input('max_price'));
        }

        // Filter deals only
        if ($request->boolean('deals_only')) {
            $query->where('is_deal', true);
        }

        // Filter featured only
        if ($request->boolean('featured_only')) {
            $query->where('is_featured', true);
        }

        // Sorting
        $sort = $request->input('sort', 'newest');
        switch ($sort) {
            case 'price_asc':
                $query->orderBy('sales_price', 'asc');
                break;
            case 'price_desc':
                $query->orderBy('sales_price', 'desc');
                break;
            case 'rating':
                $query->orderBy('rating', 'desc');
                break;
            case 'name':
                $query->orderBy('name', 'asc');
                break;
            case 'newest':
            default:
                $query->latest();
                break;
        }

        $items = $query->paginate(12)->withQueryString();
        $items->getCollection()->transform(function ($item) {
            return $item->append(['effective_price', 'total_stock']);
        });

        $categories = Category::where('is_active', true)
            ->withCount(['items' => function ($q) {
                $q->where('is_active', true);
            }])
            ->get();

        return Inertia::render('Store/Shop', [
            'items' => $items,
            'categories' => $categories,
            'filters' => $request->only(['search', 'category_id', 'min_price', 'max_price', 'deals_only', 'featured_only', 'sort']),
            'storeContext' => $context,
        ]);
    }

    /**
     * Product Details Page
     */
    public function product(Request $request, $id)
    {
        $context = $this->getStoreContext($request);

        $item = Item::where('is_active', true)
            ->with(['category', 'storeItems'])
            ->findOrFail($id);

        $item->append(['effective_price', 'total_stock']);

        $relatedItems = Item::where('is_active', true)
            ->where('category_id', $item->category_id)
            ->where('id', '!=', $item->id)
            ->with(['category', 'storeItems'])
            ->take(4)
            ->get()
            ->append(['effective_price', 'total_stock']);

        return Inertia::render('Store/Product', [
            'item' => $item,
            'relatedItems' => $relatedItems,
            'storeContext' => $context,
        ]);
    }
}
