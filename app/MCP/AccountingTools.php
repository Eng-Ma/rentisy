<?php

namespace App\MCP;

use Mcp\Capability\Attribute\McpTool;
use App\Models\Account;
use App\Models\Invoice;

class AccountingTools
{
    #[McpTool(name: 'get_accounts', description: 'Get a list of all accounts')]
    public function getAccounts(): string
    {
        $accounts = Account::all();
        if ($accounts->isEmpty()) return "No accounts found.";
        return "Found " . $accounts->count() . " accounts:\n" . $accounts->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_invoices', description: 'Get a list of invoices with optional type filter (sale, purchase, purchase_return, sale_return, bill)')]
    public function getInvoices(?string $type = null, int $limit = 20): string
    {
        $query = Invoice::with(['party', 'store', 'lines'])->orderBy('created_at', 'desc');

        if ($type) {
            if ($type === 'bill') {
                $query->whereIn('type', ['purchase', 'bill']);
            } else {
                $query->where('type', $type);
            }
        }

        $invoices = $query->take($limit)->get();
        if ($invoices->isEmpty()) return "No invoices found matching criteria.";
        return "Found " . $invoices->count() . " invoices:\n" . $invoices->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_bills', description: 'Get a list of purchase bills')]
    public function getBills(int $limit = 20): string
    {
        $bills = Invoice::whereIn('type', ['purchase', 'bill'])
            ->with(['party', 'store', 'lines'])
            ->orderBy('created_at', 'desc')
            ->take($limit)
            ->get();

        if ($bills->isEmpty()) return "No purchase bills found.";
        return "Found " . $bills->count() . " purchase bills:\n" . $bills->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_system_status', description: 'Check if the accounting system is online')]
    public function getSystemStatus(): string
    {
        return 'System is online and running Laravel ' . app()->version();
    }
}
