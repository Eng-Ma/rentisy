<?php

namespace App\Http\Controllers;

use Inertia\Inertia;
use App\Models\Invoice;
use App\Models\Party;
use App\Models\Item;
use App\Models\Account;

class DashboardController extends Controller
{
    public function index()
    {
        $totalSales = Invoice::where('type', 'sale')->sum('total_amount');
        $totalPurchases = Invoice::where('type', 'purchase')->sum('total_amount');
        
        $totalParties = Party::count();
        $totalItems = Item::count();
        $totalInvoicesCount = Invoice::count();
        
        // Net Profit Calculation
        $revenues = Account::where('type', 'revenue')
            ->withSum('journalEntryLines as total_credit', 'credit')
            ->withSum('journalEntryLines as total_debit', 'debit')
            ->get();

        $expenses = Account::where('type', 'expense')
            ->withSum('journalEntryLines as total_debit', 'debit')
            ->withSum('journalEntryLines as total_credit', 'credit')
            ->get();

        $totalRevenue = 0;
        foreach ($revenues as $rev) {
            $totalRevenue += ($rev->total_credit ?? 0) - ($rev->total_debit ?? 0);
        }

        $totalExpense = 0;
        foreach ($expenses as $exp) {
            $totalExpense += ($exp->total_debit ?? 0) - ($exp->total_credit ?? 0);
        }

        $netProfit = $totalRevenue - $totalExpense;

        return Inertia::render('Dashboard', [
            'stats' => [
                'totalSales' => number_format((float)$totalSales, 2),
                'totalPurchases' => number_format((float)$totalPurchases, 2),
                'netProfit' => number_format((float)$netProfit, 2),
                'totalParties' => $totalParties,
                'totalItems' => $totalItems,
                'totalInvoicesCount' => $totalInvoicesCount,
            ]
        ]);
    }
}
