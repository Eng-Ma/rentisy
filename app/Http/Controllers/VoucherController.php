<?php

namespace App\Http\Controllers;

use App\Models\Voucher;
use App\Models\Account;
use App\Models\Party;
use App\Models\Currency;
use App\Models\CostCenter;
use App\Models\JournalEntry;
use App\Models\Check;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class VoucherController extends Controller
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

        $vouchers = $query->paginate(15)->withQueryString();

        return Inertia::render('Vouchers/Index', [
            'vouchers' => $vouchers,
            'currentType' => $type,
        ]);
    }

    public function create(Request $request)
    {
        $type = $request->query('type', 'receipt'); // receipt or payment
        $accounts = Account::where('is_active', true)->orderBy('code')->get();
        $parties = Party::all();
        $currencies = Currency::all();
        $costCenters = CostCenter::where('is_active', true)->orderBy('code')->get();

        $cashAccounts = Account::where('type', 'asset')
            ->where(function ($q) {
                $q->where('code', 'like', '1101%')
                  ->orWhere('code', 'like', '1102%')
                  ->orWhere('name', 'like', '%صندوق%')
                  ->orWhere('name', 'like', '%بنك%')
                  ->orWhere('name', 'like', '%خزينة%');
            })->get();

        if ($cashAccounts->isEmpty()) {
            $cashAccounts = Account::where('type', 'asset')->get();
        }

        // Generate next voucher number
        $prefix = $type === 'receipt' ? 'RV-' : 'PV-';
        $lastVoucher = Voucher::where('type', $type)->latest('id')->first();
        $nextNum = $lastVoucher ? ((int)substr($lastVoucher->voucher_number, 3) + 1) : 1;
        $voucherNumber = $prefix . str_pad((string)$nextNum, 5, '0', STR_PAD_LEFT);

        return Inertia::render('Vouchers/Create', [
            'type' => $type,
            'voucherNumber' => $voucherNumber,
            'accounts' => $accounts,
            'cashAccounts' => $cashAccounts,
            'parties' => $parties,
            'currencies' => $currencies,
            'costCenters' => $costCenters,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'voucher_number' => 'required|string|unique:vouchers,voucher_number',
            'type' => 'required|in:receipt,payment',
            'payment_method' => 'required|in:cash,bank,check',
            'date' => 'required|date',
            'account_id' => 'required|exists:accounts,id',
            'party_id' => 'nullable|exists:parties,id',
            'target_account_id' => 'nullable|exists:accounts,id',
            'cost_center_id' => 'nullable|exists:cost_centers,id',
            'currency_id' => 'required|exists:currencies,id',
            'exchange_rate' => 'required|numeric|min:0.0001',
            'amount' => 'required|numeric|min:0.01',
            'check_number' => 'nullable|required_if:payment_method,check|string',
            'check_date' => 'nullable|required_if:payment_method,check|date',
            'bank_name' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        if (empty($validated['party_id']) && empty($validated['target_account_id'])) {
            return back()->withErrors(['party_id' => 'يجب اختيار العميل/المورد أو الحساب المقابل']);
        }

        DB::transaction(function () use ($validated) {
            $currency = Currency::find($validated['currency_id']);
            $rate = (float)($validated['exchange_rate'] ?? 1.0);
            $amount = (float)$validated['amount'];
            $baseAmount = $amount * $rate;
            $type = $validated['type'];

            // 1. Determine counterpart account
            $counterpartAccountId = $validated['target_account_id'];
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
                    'notes' => $validated['notes'],
                ]);
            }
        });

        return redirect()->route('vouchers.index')->with('success', 'تم حفظ السند وترحيل القيد بنجاح');
    }

    public function show(Voucher $voucher)
    {
        $voucher->load(['account', 'party', 'targetAccount', 'costCenter', 'currency', 'journalEntry.lines.account', 'checks']);

        return Inertia::render('Vouchers/Show', [
            'voucher' => $voucher,
        ]);
    }

    public function destroy(Voucher $voucher)
    {
        DB::transaction(function () use ($voucher) {
            // Delete check records
            Check::where('voucher_id', $voucher->id)->delete();

            // Delete journal entry and lines
            if ($voucher->journal_entry_id) {
                $entry = JournalEntry::find($voucher->journal_entry_id);
                if ($entry) {
                    $entry->lines()->delete();
                    $entry->delete();
                }
            }

            $voucher->delete();
        });

        return redirect()->route('vouchers.index')->with('success', 'تم حذف السند والقيد المرتبط بنجاح');
    }
}
