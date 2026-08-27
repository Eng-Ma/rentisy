<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Account;
use App\Models\JournalEntryLine;
use App\Models\Party;
use App\Models\Invoice;
use App\Models\Check;
use App\Models\CostCenter;
use App\Models\Item;
use App\Models\InvoiceLine;
use App\Models\StockTransferLine;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class ReportApiController extends Controller
{
    public function accountStatement(Request $request)
    {
        $accountId = $request->query('account_id');
        $fromDate = $request->query('from_date');
        $toDate = $request->query('to_date');

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

            $lines = $query->join('journal_entries', 'journal_entry_lines.journal_entry_id', '=', 'journal_entries.id')
                ->orderBy('journal_entries.date')
                ->select('journal_entry_lines.*')
                ->get();

            foreach ($lines as $line) {
                $totalDebit += (float)$line->debit;
                $totalCredit += (float)$line->credit;

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
                    'debit' => (float)$line->debit,
                    'credit' => (float)$line->credit,
                    'balance' => (float)$balance,
                ];
            }
        }

        return response()->json([
            'success' => true,
            'account' => $account,
            'statement' => $statement,
            'total_debit' => (float)$totalDebit,
            'total_credit' => (float)$totalCredit,
            'final_balance' => (float)$balance,
        ]);
    }

    public function trialBalance(Request $request)
    {
        $fromDate = $request->query('from_date');
        $toDate = $request->query('to_date');

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

        $accounts = $accountsQuery->orderBy('code')->get();

        $trialBalance = [];
        $sumDebit = 0;
        $sumCredit = 0;

        foreach ($accounts as $account) {
            $debit = (float)($account->total_debit ?? 0);
            $credit = (float)($account->total_credit ?? 0);
            
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

        return response()->json([
            'success' => true,
            'trial_balance' => $trialBalance,
            'sum_debit' => (float)$sumDebit,
            'sum_credit' => (float)$sumCredit,
        ]);
    }

    public function incomeStatement(Request $request)
    {
        $fromDate = $request->query('from_date');
        $toDate = $request->query('to_date');

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
            $bal = (float)(($rev->total_credit ?? 0) - ($rev->total_debit ?? 0));
            if ($bal != 0) {
                $revenueData[] = ['name' => $rev->name, 'code' => $rev->code, 'balance' => $bal];
                $totalRevenue += $bal;
            }
        }

        $totalExpense = 0;
        $expenseData = [];
        foreach ($expenses as $exp) {
            $bal = (float)(($exp->total_debit ?? 0) - ($exp->total_credit ?? 0));
            if ($bal != 0) {
                $expenseData[] = ['name' => $exp->name, 'code' => $exp->code, 'balance' => $bal];
                $totalExpense += $bal;
            }
        }

        $netIncome = $totalRevenue - $totalExpense;

        return response()->json([
            'success' => true,
            'revenues' => $revenueData,
            'expenses' => $expenseData,
            'total_revenue' => (float)$totalRevenue,
            'total_expense' => (float)$totalExpense,
            'net_income' => (float)$netIncome,
        ]);
    }

    public function partyStatement(Request $request)
    {
        $partyId = $request->query('party_id');
        $fromDate = $request->query('from_date');
        $toDate = $request->query('to_date');

        $reportData = [
            'party' => null,
            'balance' => 0,
            'total_purchases' => 0,
            'invoices' => [],
        ];

        if ($partyId) {
            $party = Party::with('account')->find($partyId);
            $reportData['party'] = $party;

            if ($party) {
                if ($party->account_id) {
                    $debit = DB::table('journal_entry_lines')->where('account_id', $party->account_id)->sum('debit');
                    $credit = DB::table('journal_entry_lines')->where('account_id', $party->account_id)->sum('credit');
                    $reportData['balance'] = ($party->type === 'customer') ? ($debit - $credit) : ($credit - $debit);
                }

                $invoicesQuery = Invoice::where('party_id', $partyId)->with('store');
                if ($fromDate) $invoicesQuery->where('date', '>=', $fromDate);
                if ($toDate) $invoicesQuery->where('date', '<=', $toDate);

                $invoices = $invoicesQuery->orderBy('date', 'desc')->get();
                $reportData['invoices'] = $invoices;

                $targetType = $party->type === 'customer' ? 'sale' : 'purchase';
                $reportData['total_purchases'] = (float)$invoices->where('type', $targetType)->sum('total_amount');
            }
        }

        return response()->json([
            'success' => true,
            'report_data' => $reportData,
        ]);
    }

    public function aging(Request $request)
    {
        $type = $request->query('type', 'customer');
        $parties = Party::where('type', $type)->with('invoices')->get();

        $today = now();
        $agingData = [];
        $totals = ['period_0_30' => 0, 'period_31_60' => 0, 'period_61_90' => 0, 'period_over_90' => 0, 'total' => 0];

        foreach ($parties as $party) {
            $pData = [
                'id' => $party->id,
                'name' => $party->name,
                'phone' => $party->phone,
                'period_0_30' => 0,
                'period_31_60' => 0,
                'period_61_90' => 0,
                'period_over_90' => 0,
                'total' => 0,
            ];

            foreach ($party->invoices as $inv) {
                $days = $today->diffInDays(Carbon::parse($inv->date));
                $amount = (float)$inv->total_amount;

                if ($days <= 30) {
                    $pData['period_0_30'] += $amount;
                    $totals['period_0_30'] += $amount;
                } elseif ($days <= 60) {
                    $pData['period_31_60'] += $amount;
                    $totals['period_31_60'] += $amount;
                } elseif ($days <= 90) {
                    $pData['period_61_90'] += $amount;
                    $totals['period_61_90'] += $amount;
                } else {
                    $pData['period_over_90'] += $amount;
                    $totals['period_over_90'] += $amount;
                }
                $pData['total'] += $amount;
                $totals['total'] += $amount;
            }

            if ($pData['total'] > 0) {
                $agingData[] = $pData;
            }
        }

        return response()->json([
            'success' => true,
            'aging_data' => $agingData,
            'totals' => $totals,
            'type' => $type,
        ]);
    }

    public function costCenters(Request $request)
    {
        $costCenterId = $request->query('cost_center_id');
        $costCenters = CostCenter::with('parent')->get();

        $reportData = [];
        $totalDebit = 0;
        $totalCredit = 0;

        if ($costCenterId) {
            $lines = JournalEntryLine::with(['account', 'journalEntry'])
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

        return response()->json([
            'success' => true,
            'cost_centers' => $costCenters,
            'selected_id' => $costCenterId,
            'report_data' => $reportData,
            'total_debit' => (float)$totalDebit,
            'total_credit' => (float)$totalCredit,
            'net_balance' => (float)($totalDebit - $totalCredit),
        ]);
    }

    public function checks(Request $request)
    {
        $type = $request->query('type');
        $status = $request->query('status');

        $query = Check::with(['party', 'currency', 'endorsedParty'])->orderBy('due_date', 'asc');

        if ($type) $query->where('type', $type);
        if ($status) $query->where('status', $status);

        $checks = $query->get();

        $stats = [
            'total_received' => (float)Check::where('type', 'received')->sum('amount'),
            'total_issued' => (float)Check::where('type', 'issued')->sum('amount'),
            'under_collection' => (float)Check::where('status', 'under_collection')->sum('amount'),
            'collected' => (float)Check::where('status', 'collected')->sum('amount'),
            'endorsed' => (float)Check::where('status', 'endorsed')->sum('amount'),
            'bounced' => (float)Check::where('status', 'bounced')->sum('amount'),
        ];

        return response()->json([
            'success' => true,
            'checks' => $checks,
            'stats' => $stats,
        ]);
    }

    public function stockMovement(Request $request)
    {
        $itemId = $request->query('item_id');
        $selectedItem = null;
        $movements = [];

        if ($itemId) {
            $selectedItem = Item::with('category')->find($itemId);

            // Invoices lines
            $invLines = InvoiceLine::with(['invoice.party', 'invoice.store'])
                ->where('item_id', $itemId)
                ->get();

            foreach ($invLines as $line) {
                if (!$line->invoice) continue;
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
            $transLines = StockTransferLine::with(['transfer.fromStore', 'transfer.toStore'])
                ->where('item_id', $itemId)
                ->get();

            foreach ($transLines as $tLine) {
                if (!$tLine->transfer) continue;
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

        return response()->json([
            'success' => true,
            'selected_item' => $selectedItem,
            'movements' => $movements,
        ]);
    }
}
