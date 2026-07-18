<?php

namespace App\Http\Controllers;

use App\Models\JournalEntry;
use App\Models\Currency;
use App\Models\Account;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\DB;

class JournalEntryController extends Controller
{
    public function index(Request $request)
    {
        $query = JournalEntry::with(['currency', 'lines.account']);

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('description', 'like', "%{$search}%")
                  ->orWhere('reference', 'like', "%{$search}%")
                  ->orWhere('id', 'like', "%{$search}%");
            });
        }
        
        if ($request->filled('date')) {
            $query->whereDate('date', $request->input('date'));
        }

        $entries = $query->latest('date')->latest('id')->paginate(10)->withQueryString();

        return Inertia::render('JournalEntries/Index', [
            'entries' => $entries,
            'filters' => $request->only(['search', 'date'])
        ]);
    }

    public function create()
    {
        $currencies = Currency::all();
        $accounts = Account::where('is_active', true)->get();
        
        return Inertia::render('JournalEntries/Create', [
            'currencies' => $currencies,
            'accounts' => $accounts
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'date' => 'required|date',
            'reference' => 'nullable|string',
            'description' => 'required|string',
            'currency_id' => 'required|exists:currencies,id',
            'exchange_rate' => 'required|numeric|min:0.000001',
            'lines' => 'required|array|min:2',
            'lines.*.account_id' => 'required|exists:accounts,id',
            'lines.*.description' => 'nullable|string',
            'lines.*.debit' => 'required|numeric|min:0',
            'lines.*.credit' => 'required|numeric|min:0',
        ]);

        // Validate balance
        $totalDebit = collect($validated['lines'])->sum('debit');
        $totalCredit = collect($validated['lines'])->sum('credit');

        if (round($totalDebit, 6) !== round($totalCredit, 6)) {
            return back()->withErrors(['lines' => 'The journal entry must be balanced (Total Debit = Total Credit).']);
        }

        if ($totalDebit == 0 && $totalCredit == 0) {
             return back()->withErrors(['lines' => 'The journal entry cannot have zero total.']);
        }

        DB::transaction(function () use ($validated) {
            $entry = JournalEntry::create([
                'date' => $validated['date'],
                'reference' => $validated['reference'],
                'description' => $validated['description'],
                'currency_id' => $validated['currency_id'],
                'exchange_rate' => $validated['exchange_rate'],
            ]);

            foreach ($validated['lines'] as $line) {
                $entry->lines()->create([
                    'account_id' => $line['account_id'],
                    'description' => $line['description'],
                    'debit' => $line['debit'],
                    'credit' => $line['credit'],
                ]);
            }
        });

        return redirect()->route('journal-entries.index')->with('success', 'Journal entry created successfully.');
    }
}
