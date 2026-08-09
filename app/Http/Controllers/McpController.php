<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Psr\Http\Message\ServerRequestInterface;
use Symfony\Bridge\PsrHttpMessage\Factory\HttpFoundationFactory;
use Mcp\Server\Server;
use Mcp\Server\Transport\StreamableHttpTransport;
use Symfony\Component\Uid\Uuid;
use Illuminate\Support\Facades\Cache;
use App\MCP\AccountingTools;

class McpController extends Controller
{
    private function configureTransport(ServerRequestInterface $psrRequest): StreamableHttpTransport
    {
        $transport = new StreamableHttpTransport($psrRequest);

        // We use Laravel Cache for IPC between the SSE GET process and POST requests.
        $transport->setOutgoingMessagesProvider(function (?Uuid $sessionId) {
            if (!$sessionId) return [];
            $key = "mcp_outgoing_{$sessionId}";
            $messages = Cache::pull($key, []); // pull to consume
            return $messages;
        });

        $transport->setResponseProvider(function ($requestId, ?Uuid $sessionId) {
            if (!$sessionId) return null;
            $key = "mcp_response_{$sessionId}_{$requestId}";
            return Cache::pull($key);
        });

        $transport->setResponseHandler(function ($response, ?Uuid $sessionId) {
            if (!$sessionId) return;
            $key = "mcp_outgoing_{$sessionId}";
            $messages = Cache::get($key, []);
            // Encode message for SSE
            $encoded = json_encode($response);
            $messages[] = ['message' => $encoded];
            Cache::put($key, $messages, 300);
        });

        return $transport;
    }

    public function handle(ServerRequestInterface $psrRequest)
    {
        // Build the server with our AccountingTools
        $server = Server::builder()
            ->setServerInfo('Laravel-Accounting-MCP', '1.0.0')
            ->addCapability(new AccountingTools())
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
