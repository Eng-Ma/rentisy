<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Account;
use App\Models\Currency;
use Illuminate\Http\Request;

class AccountApiController extends Controller
{
    public function index(Request $request)
    {
        $query = Account::with('parent');

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('code', 'like', "%{$search}%");
            });
        }

        if ($request->filled('type')) {
            $query->where('type', $request->input('type'));
        }

        $accounts = $query->orderBy('code')->get();

        return response()->json([
            'success' => true,
            'data' => $accounts,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'parent_id' => 'nullable|exists:accounts,id',
            'code' => 'required|string|unique:accounts,code',
            'name' => 'required|string',
            'type' => 'required|string|in:asset,liability,equity,revenue,expense',
            'balance_type' => 'required|string|in:debit,credit',
            'is_active' => 'boolean',
            'description' => 'nullable|string',
        ]);

        $account = Account::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'تم إنشاء الحساب بنجاح',
            'data' => $account->load('parent'),
        ], 201);
    }

    public function show(Account $account)
    {
        return response()->json([
            'success' => true,
            'data' => $account->load(['parent', 'children', 'journalEntryLines.journalEntry']),
        ]);
    }

    public function update(Request $request, Account $account)
    {
        $validated = $request->validate([
            'parent_id' => 'nullable|exists:accounts,id',
            'code' => 'required|string|unique:accounts,code,' . $account->id,
            'name' => 'required|string',
            'type' => 'required|string|in:asset,liability,equity,revenue,expense',
            'balance_type' => 'required|string|in:debit,credit',
            'is_active' => 'boolean',
            'description' => 'nullable|string',
        ]);

        $account->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'تم تحديث الحساب بنجاح',
            'data' => $account->load('parent'),
        ]);
    }

    public function destroy(Account $account)
    {
        if ($account->journalEntryLines()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'لا يمكن حذف هذا الحساب لوجود حركات وقيود محاسبية مرتبطة به.',
            ], 422);
        }

        $account->delete();

        return response()->json([
            'success' => true,
            'message' => 'تم حذف الحساب بنجاح',
        ]);
    }

    public function currencies()
    {
        $currencies = Currency::all();
        return response()->json([
            'success' => true,
            'data' => $currencies,
        ]);
    }
}
