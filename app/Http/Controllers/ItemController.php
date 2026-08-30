<?php

namespace App\Http\Controllers;

use App\Models\Item;
use App\Models\Category;
use Illuminate\Http\Request;
use Inertia\Inertia;

class ItemController extends Controller
{
    public function index(Request $request)
    {
        $query = Item::with('category');

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('barcode', 'like', "%{$search}%");
            });
        }

        $items = $query->latest()->paginate(10)->withQueryString();

        return Inertia::render('Items/Index', [
            'items' => $items,
            'filters' => $request->only(['search'])
        ]);
    }

    public function create()
    {
        $categories = Category::where('is_active', true)->get();
        return Inertia::render('Items/Create', [
            'categories' => $categories
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
            'discount_price' => 'nullable|numeric|min:0',
            'is_active' => 'boolean',
            'is_featured' => 'boolean',
            'is_deal' => 'boolean',
            'allows_points' => 'boolean',
        ]);

        $item = Item::create($validated);

        if ($request->wantsJson()) {
            return response()->json($item);
        }

        return redirect()->route('items.index')->with('success', 'تم إنشاء الصنف بنجاح.');
    }

    /**
     * Toggle points & cashback eligibility for a product.
     */
    public function togglePoints(Request $request, $id)
    {
        $item = Item::findOrFail($id);
        $item->allows_points = !$item->allows_points;
        $item->save();

        if ($request->wantsJson()) {
            return response()->json([
                'success' => true,
                'allows_points' => $item->allows_points,
                'message' => $item->allows_points ? 'تم تفعيل نظام النقاط للصنف' : 'تم استثناء الصنف من نظام النقاط',
            ]);
        }

        return back()->with('success', $item->allows_points ? 'تم تفعيل نظام النقاط والكاش باك لهذا الصنف.' : 'تم استثناء الصنف من نظام النقاط.');
    }
}
