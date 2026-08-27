<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\JournalEntry;
use App\Models\Currency;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JournalEntryApiController extends Controller
{
    public function index(Request $request)
    {
        $query = JournalEntry::with(['currency', 'lines.account', 'lines.costCenter']);

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

        $entries = $query->latest('date')->latest('id')->paginate($request->input('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $entries->items(),
            'current_page' => $entries->currentPage(),
            'last_page' => $entries->lastPage(),
            'total' => $entries->total(),
        ]);
    }

    public function show(JournalEntry $journalEntry)
    {
        return response()->json([
            'success' => true,
            'data' => $journalEntry->load(['currency', 'lines.account', 'lines.costCenter']),
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
            'lines.*.cost_center_id' => 'nullable|exists:cost_centers,id',
            'lines.*.description' => 'nullable|string',
            'lines.*.debit' => 'required|numeric|min:0',
            'lines.*.credit' => 'required|numeric|min:0',
        ]);

        $totalDebit = collect($validated['lines'])->sum('debit');
        $totalCredit = collect($validated['lines'])->sum('credit');

        if (round($totalDebit, 4) !== round($totalCredit, 4)) {
            return response()->json([
                'success' => false,
                'message' => 'القيد غير متوازن! إجمالي المدين يجب أن يساوي إجمالي الدائن تماماً.',
                'total_debit' => $totalDebit,
                'total_credit' => $totalCredit,
            ], 422);
        }

        if ($totalDebit == 0 && $totalCredit == 0) {
            return response()->json([
                'success' => false,
                'message' => 'لا يمكن حفظ قيد بمبالغ صفرية.',
            ], 422);
        }

        $entry = DB::transaction(function () use ($validated) {
            $entry = JournalEntry::create([
                'date' => $validated['date'],
                'reference' => $validated['reference'] ?? ('JE-' . strtoupper(uniqid())),
                'description' => $validated['description'],
                'currency_id' => $validated['currency_id'],
                'exchange_rate' => $validated['exchange_rate'],
            ]);

            foreach ($validated['lines'] as $line) {
                $entry->lines()->create([
                    'account_id' => $line['account_id'],
                    'cost_center_id' => $line['cost_center_id'] ?? null,
                    'description' => $line['description'] ?? null,
                    'debit' => $line['debit'],
                    'credit' => $line['credit'],
                ]);
            }

            return $entry;
        });

        return response()->json([
            'success' => true,
            'message' => 'تم حفظ وترحيل قيد اليومية بنجاح',
            'data' => $entry->load(['currency', 'lines.account', 'lines.costCenter']),
        ], 201);
    }
}
