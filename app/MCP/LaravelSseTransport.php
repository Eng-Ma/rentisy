<?php

namespace App\MCP;

use Mcp\Server\Transport\BaseTransport;
use Psr\Http\Message\ServerRequestInterface;
use Symfony\Bridge\PsrHttpMessage\Factory\HttpFoundationFactory;
use Illuminate\Http\Response;
use Mcp\Schema\JsonRpc\Error;
use Symfony\Component\Uid\Uuid;

class LaravelSseTransport extends BaseTransport
{
    private ServerRequestInterface $request;
    private ?string $immediateResponse = null;

    public function __construct(ServerRequestInterface $request)
    {
        parent::__construct();
        $this->request = $request;
    }

    public function send(string $data, array $context): void
    {
        // The Protocol calls send() when a response is ready.
        $this->immediateResponse = $data;
    }

    public function listen(): mixed
    {
        $method = $this->request->getMethod();
        
        if ($method === 'GET') {
            // Standard MCP SSE connection initialization
            $sessionId = Uuid::v4()->toRfc4122();
            
            $callback = function () use ($sessionId) {
                echo "event: endpoint\n";
                echo "data: /mcp/messages?sessionId={$sessionId}\n\n";
                ob_flush();
                flush();
                
                // Keep the connection open
                while (true) {
                    usleep(1000000); // Wait for messages or keep-alive
                }
            };
            
            return response()->stream($callback, 200, [
                'Content-Type' => 'text/event-stream',
                'Cache-Control' => 'no-cache',
                'Connection' => 'keep-alive',
                'X-Accel-Buffering' => 'no'
            ]);
        }

        if ($method === 'POST') {
            $body = (string) $this->request->getBody();
            $queryParams = $this->request->getQueryParams();
            $sessionIdStr = $queryParams['sessionId'] ?? '';
            $sessionId = $sessionIdStr ? Uuid::fromString($sessionIdStr) : null;
            
            if (is_callable($this->messageListener)) {
                // Pass the message to the protocol
                ($this->messageListener)($this, $body, $sessionId);
            }
            
            if ($this->immediateResponse !== null) {
                return response($this->immediateResponse, 200)
                    ->header('Content-Type', 'application/json');
            }
            
            // If there's no immediate response, return HTTP 202 Accepted.
            return response()->json(['status' => 'accepted'], 202);
        }
        
        return response()->json(['error' => 'Method Not Allowed'], 405);
    }
}
