<?php

namespace App\MCP;

use Mcp\Capability\Attribute\McpTool;
use App\Models\Account;
use App\Models\Invoice;

class AccountingTools
{
    #[McpTool(name: 'get_accounts', description: 'Get a list of all accounts')]
    public function getAccounts(): array
    {
        return Account::all()->toArray();
    }

    #[McpTool(name: 'get_invoices', description: 'Get a list of recent invoices')]
    public function getInvoices(int $limit = 10): array
    {
        return Invoice::orderBy('created_at', 'desc')->take($limit)->get()->toArray();
    }

    #[McpTool(name: 'get_system_status', description: 'Check if the accounting system is online')]
    public function getSystemStatus(): string
    {
        return 'System is online and running Laravel ' . app()->version();
    }
}
