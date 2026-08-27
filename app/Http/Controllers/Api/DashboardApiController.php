<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Party;
use App\Models\Item;
use App\Models\Account;
use App\Models\Voucher;
use App\Models\Check;
use App\Models\StockTransfer;
use App\Models\JournalEntry;
use Illuminate\Http\Request;

class DashboardApiController extends Controller
{
    public function index(Request $request)
    {
        $totalSales = Invoice::where('type', 'sale')->sum('total_amount');
        $totalPurchases = Invoice::where('type', 'purchase')->sum('total_amount');
        
        $totalParties = Party::count();
        $totalItems = Item::count();
        $totalInvoicesCount = Invoice::count();
        $totalVouchersCount = Voucher::count();
        $totalChecksCount = Check::count();
        $totalTransfersCount = StockTransfer::count();
        
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

        // Recent Invoices
        $recentInvoices = Invoice::with(['party', 'store'])
            ->latest('id')
            ->limit(5)
            ->get();

        // Recent Vouchers
        $recentVouchers = Voucher::with(['account', 'party'])
            ->latest('id')
            ->limit(5)
            ->get();

        // Checks summary
        $underCollectionChecks = Check::where('status', 'under_collection')->sum('amount');
        $collectedChecks = Check::where('status', 'collected')->sum('amount');

        return response()->json([
            'success' => true,
            'stats' => [
                'total_sales' => (float)$totalSales,
                'total_purchases' => (float)$totalPurchases,
                'net_profit' => (float)$netProfit,
                'total_revenue' => (float)$totalRevenue,
                'total_expense' => (float)$totalExpense,
                'total_parties' => (int)$totalParties,
                'total_items' => (int)$totalItems,
                'total_invoices_count' => (int)$totalInvoicesCount,
                'total_vouchers_count' => (int)$totalVouchersCount,
                'total_checks_count' => (int)$totalChecksCount,
                'total_transfers_count' => (int)$totalTransfersCount,
                'checks_under_collection' => (float)$underCollectionChecks,
                'checks_collected' => (float)$collectedChecks,
            ],
            'recent_invoices' => $recentInvoices,
            'recent_vouchers' => $recentVouchers,
        ]);
    }
}
