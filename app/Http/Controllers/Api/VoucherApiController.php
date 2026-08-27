<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Voucher;
use App\Models\Account;
use App\Models\Party;
use App\Models\Currency;
use App\Models\CostCenter;
use App\Models\JournalEntry;
use App\Models\Check;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class VoucherApiController extends Controller
{
    public function index(Request $request)
    {
        $type = $request->query('type'); // receipt or payment

        $query = Voucher::with(['account', 'party', 'targetAccount', 'costCenter', 'currency', 'journalEntry'])
            ->orderBy('date', 'desc')
            ->orderBy('id', 'desc');

        if ($type) {
            $query->where('type', $type);
        }

        $vouchers = $query->paginate($request->input('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $vouchers->items(),
            'current_page' => $vouchers->currentPage(),
            'last_page' => $vouchers->lastPage(),
            'total' => $vouchers->total(),
        ]);
    }

    public function show(Voucher $voucher)
    {
        return response()->json([
            'success' => true,
            'data' => $voucher->load(['account', 'party', 'targetAccount', 'costCenter', 'currency', 'journalEntry.lines.account', 'checks']),
        ]);
    }

    public function store(Request $request)
    {
        // Auto fill smart defaults for API integrations
        if (!$request->has('currency_id')) {
            $defaultCurrency = Currency::where('is_default', true)->first() ?? Currency::first();
            $request->merge(['currency_id' => $defaultCurrency?->id]);
        }
        if (!$request->has('date')) {
            $request->merge(['date' => date('Y-m-d')]);
        }
        if (!$request->has('account_id')) {
            $code = $request->input('payment_method') === 'bank' ? '1102' : '1101';
            $defaultAcc = Account::where('code', $code)->first() ?? Account::first();
            $request->merge(['account_id' => $defaultAcc?->id]);
        }
        if (!$request->has('party_id') && !$request->has('target_account_id')) {
            $expectedType = $request->input('type') === 'receipt' ? 'customer' : 'vendor';
            $defaultParty = Party::where('type', $expectedType)->first() ?? Party::first();
            if ($defaultParty) {
                $request->merge(['party_id' => $defaultParty->id]);
            } else {
                $counterCode = $request->input('type') === 'receipt' ? '4101' : '5101';
                $counterAcc = Account::where('code', $counterCode)->first() ?? Account::first();
                $request->merge(['target_account_id' => $counterAcc?->id]);
            }
        }

        $validated = $request->validate([
            'voucher_number' => 'nullable|string|unique:vouchers,voucher_number',
            'type' => 'required|in:receipt,payment',
            'payment_method' => 'required|in:cash,bank,check',
            'date' => 'required|date',
            'account_id' => 'required|exists:accounts,id',
            'party_id' => 'nullable|exists:parties,id',
            'target_account_id' => 'nullable|exists:accounts,id',
            'cost_center_id' => 'nullable|exists:cost_centers,id',
            'currency_id' => 'required|exists:currencies,id',
            'exchange_rate' => 'nullable|numeric|min:0.0001',
            'amount' => 'required|numeric|min:0.01',
            'check_number' => 'nullable|required_if:payment_method,check|string',
            'check_date' => 'nullable|required_if:payment_method,check|date',
            'bank_name' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        // Auto-generate voucher number if omitted
        if (empty($validated['voucher_number'])) {
            $prefix = $validated['type'] === 'receipt' ? 'RV-' : 'PV-';
            $lastVoucher = Voucher::where('type', $validated['type'])->latest('id')->first();
            $nextNum = $lastVoucher ? ((int)substr($lastVoucher->voucher_number, 3) + 1) : 1;
            $validated['voucher_number'] = $prefix . str_pad((string)$nextNum, 5, '0', STR_PAD_LEFT);
        }

        $voucher = DB::transaction(function () use ($validated) {
            $currency = Currency::find($validated['currency_id']);
            $rate = (float)($validated['exchange_rate'] ?? 1.0);
            $amount = (float)$validated['amount'];
            $baseAmount = $amount * $rate;
            $type = $validated['type'];

            // 1. Determine counterpart account
            $counterpartAccountId = $validated['target_account_id'] ?? null;
            if (!$counterpartAccountId && !empty($validated['party_id'])) {
                $party = Party::find($validated['party_id']);
                $counterpartAccountId = $party->account_id;
                if (!$counterpartAccountId) {
                    $defaultCode = $type === 'receipt' ? '1103' : '2101';
                    $counterpartAccountId = Account::where('code', $defaultCode)->first()?->id;
                }
            }

            // 2. Create Journal Entry
            $typeLabel = $type === 'receipt' ? 'سند قبض' : 'سند صرف';
            $journalEntry = JournalEntry::create([
                'date' => $validated['date'],
                'reference' => $validated['voucher_number'],
                'description' => "{$typeLabel} رقم {$validated['voucher_number']} - " . ($validated['notes'] ?? ''),
                'currency_id' => $currency->id,
                'exchange_rate' => $rate,
            ]);

            if ($type === 'receipt') {
                // Debit: Cash/Bank/Check account
                $journalEntry->lines()->create([
                    'account_id' => $validated['account_id'],
                    'cost_center_id' => $validated['cost_center_id'] ?? null,
                    'description' => "قبض نقدي/بنكي - {$validated['voucher_number']}",
                    'debit' => $baseAmount,
                    'credit' => 0,
                ]);
                // Credit: Party/Target account
                $journalEntry->lines()->create([
                    'account_id' => $counterpartAccountId ?? $validated['account_id'],
                    'cost_center_id' => $validated['cost_center_id'] ?? null,
                    'description' => "تسديد/إيراد - {$validated['voucher_number']}",
                    'debit' => 0,
                    'credit' => $baseAmount,
                ]);
            } else {
                // Debit: Party/Expense account
                $journalEntry->lines()->create([
                    'account_id' => $counterpartAccountId ?? $validated['account_id'],
                    'cost_center_id' => $validated['cost_center_id'] ?? null,
                    'description' => "دفع/مصروف - {$validated['voucher_number']}",
                    'debit' => $baseAmount,
                    'credit' => 0,
                ]);
                // Credit: Cash/Bank/Check account
                $journalEntry->lines()->create([
                    'account_id' => $validated['account_id'],
                    'cost_center_id' => $validated['cost_center_id'] ?? null,
                    'description' => "صرف نقدي/بنكي - {$validated['voucher_number']}",
                    'debit' => 0,
                    'credit' => $baseAmount,
                ]);
            }

            // 3. Create Voucher
            $validated['journal_entry_id'] = $journalEntry->id;
            $voucher = Voucher::create($validated);

            // 4. If Check payment method, register into Checks portfolio
            if ($validated['payment_method'] === 'check' && !empty($validated['check_number'])) {
                Check::create([
                    'check_number' => $validated['check_number'],
                    'type' => $type === 'receipt' ? 'received' : 'issued',
                    'bank_name' => $validated['bank_name'] ?? 'البنك',
                    'due_date' => $validated['check_date'] ?? $validated['date'],
                    'issue_date' => $validated['date'],
                    'amount' => $amount,
                    'currency_id' => $currency->id,
                    'status' => 'under_collection',
                    'party_id' => $validated['party_id'] ?? null,
                    'voucher_id' => $voucher->id,
                    'journal_entry_id' => $journalEntry->id,
                    'notes' => $validated['notes'] ?? null,
                ]);
            }

            return $voucher;
        });

        return response()->json([
            'success' => true,
            'message' => 'تم حفظ السند وترحيل القيد المحاسبي بنجاح',
            'data' => $voucher->load(['account', 'party', 'targetAccount', 'costCenter', 'currency', 'journalEntry']),
        ], 201);
    }

    public function destroy(Voucher $voucher)
    {
        DB::transaction(function () use ($voucher) {
            Check::where('voucher_id', $voucher->id)->delete();

            if ($voucher->journal_entry_id) {
                $entry = JournalEntry::find($voucher->journal_entry_id);
                if ($entry) {
                    $entry->lines()->delete();
                    $entry->delete();
                }
            }

            $voucher->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'تم حذف السند والقيد المرتبط بنجاح',
        ]);
    }
}
