<?php

namespace App\Http\Controllers;

use App\Models\Store;
use Illuminate\Http\Request;
use Inertia\Inertia;

class StoreController extends Controller
{
    public function index()
    {
        $stores = Store::where('is_active', true)->get();
        return response()->json($stores);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string',
            'code' => 'nullable|string',
            'location' => 'nullable|string',
        ]);

        $store = Store::create($validated);

        if ($request->wantsJson()) {
            return response()->json($store);
        }

        return back()->with('success', 'تم إنشاء المستودع بنجاح');
    }
}
