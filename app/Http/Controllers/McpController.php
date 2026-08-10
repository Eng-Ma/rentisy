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

        // Build the server with full CRUD AccountingTools (Queries, Creates, Updates, Deletions)
        $server = Server::builder()
            ->setServerInfo('Laravel-Accounting-MCP', '2.0.0')
            ->setSession($sessionStore)
            // Queries
            ->addTool([$accountingTools, 'getAccounts'])
            ->addTool([$accountingTools, 'getInvoices'])
            ->addTool([$accountingTools, 'getBills'])
            ->addTool([$accountingTools, 'getSystemStatus'])
            ->addTool([$accountingTools, 'getParties'])
            ->addTool([$accountingTools, 'getItems'])
            ->addTool([$accountingTools, 'getStores'])
            ->addTool([$accountingTools, 'getCategories'])
            // Creation Tools
            ->addTool([$accountingTools, 'createCustomer'])
            ->addTool([$accountingTools, 'createVendor'])
            ->addTool([$accountingTools, 'createItem'])
            ->addTool([$accountingTools, 'createStore'])
            ->addTool([$accountingTools, 'createCategory'])
            ->addTool([$accountingTools, 'createInvoice'])
            ->addTool([$accountingTools, 'createAccount'])
            ->addTool([$accountingTools, 'createJournalEntry'])
            // Update Tools
            ->addTool([$accountingTools, 'updateParty'])
            ->addTool([$accountingTools, 'updateItem'])
            ->addTool([$accountingTools, 'updateStore'])
            ->addTool([$accountingTools, 'updateCategory'])
            ->addTool([$accountingTools, 'updateAccount'])
            // Deletion Tools
            ->addTool([$accountingTools, 'deleteInvoice'])
            ->addTool([$accountingTools, 'deleteParty'])
            ->addTool([$accountingTools, 'deleteItem'])
            ->addTool([$accountingTools, 'deleteStore'])
            ->addTool([$accountingTools, 'deleteCategory'])
            ->addTool([$accountingTools, 'deleteAccount'])
            ->addTool([$accountingTools, 'deleteJournalEntry'])
            ->build();

        $transport = new LaravelSseTransport($psrRequest);

        // Run the server on the transport which listens and handles the request
        return $server->run($transport);
    }
}
