<?php

namespace App\Http\Controllers;

use App\Models\Account;
use Illuminate\Http\Request;
use Inertia\Inertia;

class AccountController extends Controller
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

        $accounts = $query->latest()->paginate(10)->withQueryString();

        return Inertia::render('Accounts/Index', [
            'accounts' => $accounts,
            'filters' => $request->only(['search', 'type'])
        ]);
    }

    public function create()
    {
        $parentAccounts = Account::where('is_active', true)->get();
        return Inertia::render('Accounts/Create', [
            'parentAccounts' => $parentAccounts
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

        Account::create($validated);

        return redirect()->route('accounts.index')->with('success', 'Account created successfully.');
    }

    // edit, update, destroy omitted for brevity in MVP...
}
