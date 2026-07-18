<?php

namespace App\Http\Controllers;

use App\Models\Party;
use App\Models\Account;
use Illuminate\Http\Request;
use Inertia\Inertia;

class PartyController extends Controller
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

        $parties = $query->latest()->paginate(10)->withQueryString();

        return Inertia::render('Parties/Index', [
            'parties' => $parties,
            'filters' => $request->only(['search', 'type'])
        ]);
    }

    public function create()
    {
        $accounts = Account::where('is_active', true)->get();
        return Inertia::render('Parties/Create', [
            'accounts' => $accounts
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'type' => 'required|in:customer,vendor',
            'name' => 'required|string',
            'phone' => 'nullable|string',
            'address' => 'nullable|string',
            'account_id' => 'nullable|exists:accounts,id',
        ]);

        $party = Party::create($validated);

        if ($request->wantsJson()) {
            return response()->json($party);
        }

        return redirect()->route('parties.index')->with('success', 'Party created successfully.');
    }
}
