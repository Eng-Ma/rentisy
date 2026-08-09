<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Psr\Http\Message\ServerRequestInterface;
use Symfony\Bridge\PsrHttpMessage\Factory\HttpFoundationFactory;
use Mcp\Server;
use Mcp\Server\Transport\StreamableHttpTransport;
use Symfony\Component\Uid\Uuid;
use Illuminate\Support\Facades\Cache;
use App\MCP\AccountingTools;

class McpController extends Controller
{
    private function configureTransport(ServerRequestInterface $psrRequest): StreamableHttpTransport
    {
        $transport = new StreamableHttpTransport($psrRequest);

        return $transport;
    }

    public function handle(ServerRequestInterface $psrRequest)
    {
        $accountingTools = new AccountingTools();

        // Build the server with our AccountingTools
        $server = Server::builder()
            ->setServerInfo('Laravel-Accounting-MCP', '1.0.0')
            ->addTool([$accountingTools, 'getAccounts'])
            ->addTool([$accountingTools, 'getInvoices'])
            ->addTool([$accountingTools, 'getSystemStatus'])
            ->build();

        $transport = $this->configureTransport($psrRequest);

        // Connect the server to our transport
        $server->connect($transport);

        // The transport listens and handles the request (SSE GET or Message POST)
        $psrResponse = $transport->listen();

        // Convert PSR-7 Response back to Laravel (Symfony) Response
        $httpFoundationFactory = new HttpFoundationFactory();
        return $httpFoundationFactory->createResponse($psrResponse);
    }
}
