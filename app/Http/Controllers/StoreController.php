<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

use App\Models\Store;

class StoreController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'location' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $store = Store::create($validated);

        if ($request->wantsJson()) {
            return response()->json($store);
        }

        return redirect()->route('stores.index')->with('success', 'Store created successfully.');
    }
}
