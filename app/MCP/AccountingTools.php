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

    #[McpTool(name: 'get_invoices', description: 'Get a list of recent invoices')]
    public function getInvoices(int $limit = 10): string
    {
        $invoices = Invoice::orderBy('created_at', 'desc')->take($limit)->get();
        if ($invoices->isEmpty()) return "No invoices found.";
        return "Found " . $invoices->count() . " invoices:\n" . $invoices->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_system_status', description: 'Check if the accounting system is online')]
    public function getSystemStatus(): string
    {
        return 'System is online and running Laravel ' . app()->version();
    }
}
