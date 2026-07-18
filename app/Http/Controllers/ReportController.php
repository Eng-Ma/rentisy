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
}
