<?php

namespace App\Http\Controllers;

use App\Models\Account;
use App\Models\JournalEntryLine;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function index()
    {
        return Inertia::render('Reports/Index');
    }

    public function accountStatement(Request $request)
    {
        $accountId = $request->query('account_id');
        $fromDate = $request->query('from_date');
        $toDate = $request->query('to_date');

        $accounts = Account::all();
        $statement = [];
        $account = null;
        $totalDebit = 0;
        $totalCredit = 0;
        $balance = 0;

        if ($accountId) {
            $account = Account::find($accountId);
            $query = JournalEntryLine::with('journalEntry')
                ->where('account_id', $accountId);

            if ($fromDate) {
                $query->whereHas('journalEntry', function($q) use ($fromDate) {
                    $q->where('date', '>=', $fromDate);
                });
            }
            if ($toDate) {
                $query->whereHas('journalEntry', function($q) use ($toDate) {
                    $q->where('date', '<=', $toDate);
                });
            }

            // Order by date
            $lines = $query->join('journal_entries', 'journal_entry_lines.journal_entry_id', '=', 'journal_entries.id')
                ->orderBy('journal_entries.date')
                ->select('journal_entry_lines.*')
                ->get();

            foreach ($lines as $line) {
                $totalDebit += $line->debit;
                $totalCredit += $line->credit;
                // Calculate running balance based on account nature
                if ($account->balance_type === 'debit') {
                    $balance += ($line->debit - $line->credit);
                } else {
                    $balance += ($line->credit - $line->debit);
                }

                $statement[] = [
                    'id' => $line->id,
                    'date' => $line->journalEntry->date,
                    'reference' => $line->journalEntry->reference,
                    'description' => $line->description ?: $line->journalEntry->description,
                    'debit' => $line->debit,
                    'credit' => $line->credit,
                    'balance' => $balance,
                ];
            }
        }

        return Inertia::render('Reports/AccountStatement', [
            'accounts' => $accounts,
            'statement' => $statement,
            'account' => $account,
            'totalDebit' => $totalDebit,
            'totalCredit' => $totalCredit,
            'finalBalance' => $balance,
            'filters' => $request->only(['account_id', 'from_date', 'to_date'])
        ]);
    }

    public function trialBalance(Request $request)
    {
        $fromDate = $request->query('from_date');
        $toDate = $request->query('to_date');

        // Simple Trial Balance (Sums up all lines per account)
        $accountsQuery = Account::query();
        
        $accountsQuery->withSum(['journalEntryLines as total_debit' => function($q) use ($fromDate, $toDate) {
            if ($fromDate || $toDate) {
                $q->whereHas('journalEntry', function($jeQuery) use ($fromDate, $toDate) {
                    if ($fromDate) $jeQuery->where('date', '>=', $fromDate);
                    if ($toDate) $jeQuery->where('date', '<=', $toDate);
                });
            }
        }], 'debit');

        $accountsQuery->withSum(['journalEntryLines as total_credit' => function($q) use ($fromDate, $toDate) {
            if ($fromDate || $toDate) {
                $q->whereHas('journalEntry', function($jeQuery) use ($fromDate, $toDate) {
                    if ($fromDate) $jeQuery->where('date', '>=', $fromDate);
                    if ($toDate) $jeQuery->where('date', '<=', $toDate);
                });
            }
        }], 'credit');

        $accounts = $accountsQuery->get();

        $trialBalance = [];
        $sumDebit = 0;
        $sumCredit = 0;

        foreach ($accounts as $account) {
            $debit = $account->total_debit ?? 0;
            $credit = $account->total_credit ?? 0;
            
            // Calculate final balance per account
            $balance = 0;
            $balanceType = '';
            
            if ($debit > $credit) {
                $balance = $debit - $credit;
                $balanceType = 'debit';
                $sumDebit += $balance;
            } elseif ($credit > $debit) {
                $balance = $credit - $debit;
                $balanceType = 'credit';
                $sumCredit += $balance;
            }

            if ($debit > 0 || $credit > 0) {
                $trialBalance[] = [
                    'code' => $account->code,
                    'name' => $account->name,
                    'total_debit' => $debit,
                    'total_credit' => $credit,
                    'balance' => $balance,
                    'balance_type' => $balanceType,
                ];
            }
        }

        return Inertia::render('Reports/TrialBalance', [
            'trialBalance' => $trialBalance,
            'sumDebit' => $sumDebit,
            'sumCredit' => $sumCredit,
            'filters' => $request->only(['from_date', 'to_date']),
        ]);
    }

    public function incomeStatement(Request $request)
    {
        $fromDate = $request->query('from_date');
        $toDate = $request->query('to_date');

        // Revenue minus Expenses
        $revenuesQuery = Account::where('type', 'revenue');
        $expensesQuery = Account::where('type', 'expense');

        $applyFilters = function($q) use ($fromDate, $toDate) {
            if ($fromDate || $toDate) {
                $q->whereHas('journalEntry', function($jeQuery) use ($fromDate, $toDate) {
                    if ($fromDate) $jeQuery->where('date', '>=', $fromDate);
                    if ($toDate) $jeQuery->where('date', '<=', $toDate);
                });
            }
        };

        $revenuesQuery->withSum(['journalEntryLines as total_debit' => $applyFilters], 'debit')
                      ->withSum(['journalEntryLines as total_credit' => $applyFilters], 'credit');

        $expensesQuery->withSum(['journalEntryLines as total_debit' => $applyFilters], 'debit')
                      ->withSum(['journalEntryLines as total_credit' => $applyFilters], 'credit');

        $revenues = $revenuesQuery->get();
        $expenses = $expensesQuery->get();

        $totalRevenue = 0;
        $revenueData = [];
        foreach ($revenues as $rev) {
            $bal = ($rev->total_credit ?? 0) - ($rev->total_debit ?? 0); // Revenues are normally credit
            if ($bal != 0) {
                $revenueData[] = ['name' => $rev->name, 'balance' => $bal];
                $totalRevenue += $bal;
            }
        }

        $totalExpense = 0;
        $expenseData = [];
        foreach ($expenses as $exp) {
            $bal = ($exp->total_debit ?? 0) - ($exp->total_credit ?? 0); // Expenses are normally debit
            if ($bal != 0) {
                $expenseData[] = ['name' => $exp->name, 'balance' => $bal];
                $totalExpense += $bal;
            }
        }

        $netIncome = $totalRevenue - $totalExpense;

        return Inertia::render('Reports/IncomeStatement', [
            'revenueData' => $revenueData,
            'expenseData' => $expenseData,
            'totalRevenue' => $totalRevenue,
            'totalExpense' => $totalExpense,
            'netIncome' => $netIncome,
            'filters' => $request->only(['from_date', 'to_date']),
        ]);
    }

    public function partyReport(Request $request)
    {
        $partyId = $request->query('party_id');
        $fromDate = $request->query('from_date');
        $toDate = $request->query('to_date');

        // Fetch all parties for the dropdown search
        $parties = \App\Models\Party::all();
        
        $reportData = [
            'party' => null,
            'balance' => 0,
            'totalPurchases' => 0,
            'invoices' => []
        ];

        if ($partyId) {
            $party = \App\Models\Party::with('account')->find($partyId);
            $reportData['party'] = $party;

            if ($party) {
                // Calculate Account Balance if they have an account linked
                if ($party->account_id) {
                    $debit = DB::table('journal_entry_lines')->where('account_id', $party->account_id)->sum('debit');
                    $credit = DB::table('journal_entry_lines')->where('account_id', $party->account_id)->sum('credit');
                    // Usually customers are debit balance, suppliers are credit balance
                    $reportData['balance'] = ($party->type === 'customer') ? ($debit - $credit) : ($credit - $debit);
                }

                // Query Invoices
                $invoicesQuery = \App\Models\Invoice::where('party_id', $partyId)->with('store');
                
                if ($fromDate) {
                    $invoicesQuery->where('date', '>=', $fromDate);
                }
                if ($toDate) {
                    $invoicesQuery->where('date', '<=', $toDate);
                }

                $invoices = $invoicesQuery->orderBy('date', 'desc')->get();
                $reportData['invoices'] = $invoices;

                // Total purchases from us (their purchases = our sales)
                // For a customer, total purchases = sum of 'sale' invoices
                // For a supplier, total purchases from them = sum of 'purchase' invoices
                $targetType = $party->type === 'customer' ? 'sale' : 'purchase';
                $reportData['totalPurchases'] = $invoices->where('type', $targetType)->sum('total_amount');
            }
        }

        return Inertia::render('Reports/PartyReport', [
            'parties' => $parties,
            'reportData' => $reportData,
            'filters' => $request->only(['party_id', 'from_date', 'to_date'])
        ]);
    }

    public function aging(Request $request)
    {
        $type = $request->query('type', 'customer'); // customer or vendor
        $parties = \App\Models\Party::where('type', $type)->with('invoices')->get();

        $today = now();
        $agingData = [];
        $totals = ['0_30' => 0, '31_60' => 0, '61_90' => 0, 'over_90' => 0, 'total' => 0];

        foreach ($parties as $party) {
            $pData = [
                'id' => $party->id,
                'name' => $party->name,
                'phone' => $party->phone,
                '0_30' => 0,
                '31_60' => 0,
                '61_90' => 0,
                'over_90' => 0,
                'total' => 0,
            ];

            foreach ($party->invoices as $inv) {
                $days = $today->diffInDays(\Carbon\Carbon::parse($inv->date));
                $amount = (float)$inv->total_amount;

                if ($days <= 30) {
                    $pData['0_30'] += $amount;
                    $totals['0_30'] += $amount;
                } elseif ($days <= 60) {
                    $pData['31_60'] += $amount;
                    $totals['31_60'] += $amount;
                } elseif ($days <= 90) {
                    $pData['61_90'] += $amount;
                    $totals['61_90'] += $amount;
                } else {
                    $pData['over_90'] += $amount;
                    $totals['over_90'] += $amount;
                }
                $pData['total'] += $amount;
                $totals['total'] += $amount;
            }

            if ($pData['total'] > 0) {
                $agingData[] = $pData;
            }
        }

        return Inertia::render('Reports/Aging', [
            'agingData' => $agingData,
            'totals' => $totals,
            'type' => $type,
        ]);
    }

    public function costCenters(Request $request)
    {
        $costCenters = \App\Models\CostCenter::with(['parent'])->get();
        $costCenterId = $request->query('cost_center_id');

        $reportData = [];
        $totalDebit = 0;
        $totalCredit = 0;

        if ($costCenterId) {
            $lines = \App\Models\JournalEntryLine::with(['account', 'journalEntry'])
                ->where('cost_center_id', $costCenterId)
                ->get();

            foreach ($lines as $l) {
                $totalDebit += (float)$l->debit;
                $totalCredit += (float)$l->credit;
                $reportData[] = [
                    'date' => $l->journalEntry?->date,
                    'reference' => $l->journalEntry?->reference,
                    'account_name' => $l->account?->name,
                    'account_code' => $l->account?->code,
                    'description' => $l->description ?: $l->journalEntry?->description,
                    'debit' => (float)$l->debit,
                    'credit' => (float)$l->credit,
                ];
            }
        }

        return Inertia::render('Reports/CostCenters', [
            'costCenters' => $costCenters,
            'selectedId' => $costCenterId,
            'reportData' => $reportData,
            'totalDebit' => $totalDebit,
            'totalCredit' => $totalCredit,
            'netBalance' => $totalDebit - $totalCredit,
        ]);
    }

    public function checks(Request $request)
    {
        $type = $request->query('type');
        $status = $request->query('status');

        $query = \App\Models\Check::with(['party', 'currency', 'endorsedParty'])->orderBy('due_date', 'asc');

        if ($type) $query->where('type', $type);
        if ($status) $query->where('status', $status);

        $checks = $query->get();

        $stats = [
            'total_received' => \App\Models\Check::where('type', 'received')->sum('amount'),
            'total_issued' => \App\Models\Check::where('type', 'issued')->sum('amount'),
            'under_collection' => \App\Models\Check::where('status', 'under_collection')->sum('amount'),
            'collected' => \App\Models\Check::where('status', 'collected')->sum('amount'),
        ];

        return Inertia::render('Reports/Checks', [
            'checks' => $checks,
            'stats' => $stats,
            'filters' => $request->only(['type', 'status']),
        ]);
    }

    public function stockMovement(Request $request)
    {
        $itemId = $request->query('item_id');
        $items = \App\Models\Item::all();

        $movements = [];
        $selectedItem = null;

        if ($itemId) {
            $selectedItem = \App\Models\Item::with('category')->find($itemId);

            // Invoices lines
            $invLines = \App\Models\InvoiceLine::with(['invoice.party', 'invoice.store'])
                ->where('item_id', $itemId)
                ->get();

            foreach ($invLines as $line) {
                $isAddition = in_array($line->invoice->type, ['purchase', 'sale_return']);
                $movements[] = [
                    'date' => $line->invoice->date,
                    'type' => $line->invoice->type,
                    'reference' => 'INV-' . $line->invoice->id,
                    'party_name' => $line->invoice->party?->name ?? 'عميل/مورد',
                    'store_name' => $line->invoice->store?->name ?? 'المستودع الرئيسي',
                    'in_qty' => $isAddition ? (float)$line->quantity : 0,
                    'out_qty' => !$isAddition ? (float)$line->quantity : 0,
                    'unit_price' => (float)$line->unit_price,
                ];
            }

            // Transfer lines
            $transLines = \App\Models\StockTransferLine::with(['transfer.fromStore', 'transfer.toStore'])
                ->where('item_id', $itemId)
                ->get();

            foreach ($transLines as $tLine) {
                $movements[] = [
                    'date' => $tLine->transfer->date,
                    'type' => $tLine->transfer->type,
                    'reference' => $tLine->transfer->transfer_number,
                    'party_name' => 'مناقلة مستودعية',
                    'store_name' => ($tLine->transfer->fromStore?->name ?? 'مستودع') . ' -> ' . ($tLine->transfer->toStore?->name ?? 'مستودع'),
                    'in_qty' => $tLine->transfer->type === 'stock_in' ? (float)$tLine->quantity : 0,
                    'out_qty' => $tLine->transfer->type === 'stock_out' ? (float)$tLine->quantity : 0,
                    'unit_price' => (float)$tLine->unit_cost,
                ];
            }

            usort($movements, fn($a, $b) => strcmp($b['date'], $a['date']));
        }

        return Inertia::render('Reports/StockMovement', [
            'items' => $items,
            'selectedItem' => $selectedItem,
            'movements' => $movements,
        ]);
    }
}
