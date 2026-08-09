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
            $sessionId = Uuid::v4()->toRfc4122();
            
            $callback = function () use ($sessionId) {
                // Release the session lock to prevent hanging other requests from the same user
                session_write_close();
                
                // Make endpoint absolute to satisfy strict clients
                $endpoint = url('/mcp/messages?sessionId=' . $sessionId);
                echo "event: endpoint\n";
                echo "data: {$endpoint}\n\n";
                ob_flush();
                flush();
                
                // Keep the connection open and send pings to prevent 504 Gateway Timeout
                while (true) {
                    sleep(15);
                    echo ": keepalive\n\n";
                    ob_flush();
                    flush();
                    
                    // Prevent PHP-FPM zombie processes by exiting if client disconnected
                    if (connection_aborted()) {
                        break;
                    }
                }
            };
            
            return response()->stream($callback, 200, [
                'Content-Type' => 'text/event-stream',
                'Cache-Control' => 'no-cache',
                'Connection' => 'keep-alive',
                'X-Accel-Buffering' => 'no',
                'Access-Control-Allow-Origin' => '*',
            ]);
        }

        if ($method === 'OPTIONS') {
            return response('', 204)
                ->header('Access-Control-Allow-Origin', '*')
                ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
                ->header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
        }

        if ($method === 'POST') {
            $body = (string) $this->request->getBody();
            $queryParams = $this->request->getQueryParams();
            $clientSessionIdStr = $queryParams['sessionId'] ?? '';
            
            // Check if this is the initialize request
            $isInitialize = str_contains($body, '"method":"initialize"');
            
            $internalSessionId = null;

            if ($isInitialize) {
                // The PHP SDK strictly forbids passing a session ID during initialization
                // and internally generates a new one. We pass null to let it generate it.
                if (is_callable($this->messageListener)) {
                    ($this->messageListener)($this, $body, null);
                }
                
                // The SDK generated a new session ID and saved it in $this->sessionId.
                // We must map the client's session ID to this internal session ID.
                if ($this->sessionId && $clientSessionIdStr) {
                    \Illuminate\Support\Facades\Cache::put('mcp_session_map_' . $clientSessionIdStr, $this->sessionId->toRfc4122(), 3600);
                }
            } else {
                // For subsequent requests, lookup the internal session ID
                $mappedIdStr = \Illuminate\Support\Facades\Cache::get('mcp_session_map_' . $clientSessionIdStr);
                $internalSessionId = $mappedIdStr ? Uuid::fromString($mappedIdStr) : ($clientSessionIdStr ? Uuid::fromString($clientSessionIdStr) : null);
                
                if (is_callable($this->messageListener)) {
                    ($this->messageListener)($this, $body, $internalSessionId);
                }
            }
            
            if ($this->immediateResponse !== null) {
                return response($this->immediateResponse, 200)
                    ->header('Content-Type', 'application/json')
                    ->header('Access-Control-Allow-Origin', '*');
            }
            
            return response()->json(['status' => 'accepted'], 202)->header('Access-Control-Allow-Origin', '*');
        }
        
        return response()->json(['error' => 'Method Not Allowed'], 405);
    }
}
