<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Party;
use App\Models\Account;
use Illuminate\Http\Request;

class PartyApiController extends Controller
{
    public function index(Request $request)
    {
        $query = Party::with('account');

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhere('address', 'like', "%{$search}%");
            });
        }

        if ($request->filled('type')) {
            $query->where('type', $request->input('type'));
        }

        $parties = $query->orderBy('name')->get();

        return response()->json([
            'success' => true,
            'data' => $parties,
        ]);
    }

    public function show(Party $party)
    {
        return response()->json([
            'success' => true,
            'data' => $party->load(['account', 'invoices', 'quotations', 'checks']),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'type' => 'required|in:customer,vendor',
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:50',
            'address' => 'nullable|string',
            'account_id' => 'nullable|exists:accounts,id',
        ]);

        $party = Party::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'تمت إضافة الطرف (عميل/مورد) بنجاح',
            'data' => $party->load('account'),
        ], 201);
    }

    public function update(Request $request, Party $party)
    {
        $validated = $request->validate([
            'type' => 'required|in:customer,vendor',
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:50',
            'address' => 'nullable|string',
            'account_id' => 'nullable|exists:accounts,id',
        ]);

        $party->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'تم تحديث بيانات الطرف بنجاح',
            'data' => $party->load('account'),
        ]);
    }

    public function destroy(Party $party)
    {
        if ($party->invoices()->count() > 0 || $party->vouchers()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'لا يمكن حذف الطرف لوجود فواتير أو سندات مرتبطة به.',
            ], 422);
        }

        $party->delete();

        return response()->json([
            'success' => true,
            'message' => 'تم حذف الطرف بنجاح',
        ]);
    }
}
