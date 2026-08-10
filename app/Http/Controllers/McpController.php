<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Psr\Http\Message\ServerRequestInterface;
use Symfony\Bridge\PsrHttpMessage\Factory\HttpFoundationFactory;
use Mcp\Server;
use Symfony\Component\Uid\Uuid;
use Illuminate\Support\Facades\Cache;
use App\MCP\AccountingTools;
use App\MCP\LaravelSseTransport;

class McpController extends Controller
{
    public function handle(ServerRequestInterface $psrRequest)
    {
        $accountingTools = new AccountingTools();
        $sessionStore = new \App\MCP\LaravelCacheSessionStore();

        // Build the server with all AccountingTools (query & admin operations)
        $server = Server::builder()
            ->setServerInfo('Laravel-Accounting-MCP', '1.1.0')
            ->setSession($sessionStore)
            // Queries
            ->addTool([$accountingTools, 'getAccounts'])
            ->addTool([$accountingTools, 'getInvoices'])
            ->addTool([$accountingTools, 'getBills'])
            ->addTool([$accountingTools, 'getSystemStatus'])
            ->addTool([$accountingTools, 'getParties'])
            ->addTool([$accountingTools, 'getItems'])
            ->addTool([$accountingTools, 'getStores'])
            // Admin Operations (Writes)
            ->addTool([$accountingTools, 'createCustomer'])
            ->addTool([$accountingTools, 'createVendor'])
            ->addTool([$accountingTools, 'createItem'])
            ->addTool([$accountingTools, 'createInvoice'])
            ->addTool([$accountingTools, 'createAccount'])
            ->addTool([$accountingTools, 'createJournalEntry'])
            ->build();

        $transport = new LaravelSseTransport($psrRequest);

        // Run the server on the transport which listens and handles the request
        return $server->run($transport);
    }
}
