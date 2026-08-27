<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Item;
use App\Models\Category;
use App\Models\Store;
use App\Models\StoreItem;
use Illuminate\Http\Request;

class ItemApiController extends Controller
{
    public function index(Request $request)
    {
        $query = Item::with(['category', 'storeItems.store']);

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('barcode', 'like', "%{$search}%");
            });
        }

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->input('category_id'));
        }

        $items = $query->orderBy('name')->get();

        return response()->json([
            'success' => true,
            'data' => $items,
        ]);
    }

    public function show(Item $item)
    {
        return response()->json([
            'success' => true,
            'data' => $item->load(['category', 'storeItems.store']),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'category_id' => 'nullable|exists:categories,id',
            'barcode' => 'nullable|string|unique:items,barcode',
            'name' => 'required|string',
            'description' => 'nullable|string',
            'unit' => 'required|string',
            'purchase_price' => 'required|numeric|min:0',
            'sales_price' => 'required|numeric|min:0',
            'is_active' => 'boolean',
        ]);

        $item = Item::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'تم إنشاء الصنف بنجاح',
            'data' => $item->load('category'),
        ], 201);
    }

    public function update(Request $request, Item $item)
    {
        $validated = $request->validate([
            'category_id' => 'nullable|exists:categories,id',
            'barcode' => 'nullable|string|unique:items,barcode,' . $item->id,
            'name' => 'required|string',
            'description' => 'nullable|string',
            'unit' => 'required|string',
            'purchase_price' => 'required|numeric|min:0',
            'sales_price' => 'required|numeric|min:0',
            'is_active' => 'boolean',
        ]);

        $item->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'تم تحديث بيانات الصنف بنجاح',
            'data' => $item->load('category'),
        ]);
    }

    public function destroy(Item $item)
    {
        $item->delete();
        return response()->json([
            'success' => true,
            'message' => 'تم حذف الصنف بنجاح',
        ]);
    }

    public function categories()
    {
        $categories = Category::withCount('items')->get();
        return response()->json([
            'success' => true,
            'data' => $categories,
        ]);
    }

    public function storeCategory(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $category = Category::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'تم إضافة التصنيف بنجاح',
            'data' => $category,
        ], 201);
    }

    public function stores()
    {
        $stores = Store::withCount('storeItems')->get();
        return response()->json([
            'success' => true,
            'data' => $stores,
        ]);
    }

    public function storeStore(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'location' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $store = Store::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'تم إضافة المستودع بنجاح',
            'data' => $store,
        ], 201);
    }
}
