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
    private ?string $latestMessage = null;

    public function __construct(ServerRequestInterface $request)
    {
        parent::__construct();
        $this->request = $request;
    }

    public function send(string $data, array $context): void
    {
        $this->latestMessage = $data;
        // In PHP-FPM, POST requests and GET (SSE) requests run in different processes.
        // We MUST use Cache to pass the JSON-RPC response from the POST worker to the SSE worker!
        $queryParams = $this->request->getQueryParams();
        $clientSessionIdStr = $queryParams['sessionId'] ?? '';
        
        if ($clientSessionIdStr) {
            $cacheKey = 'mcp_messages_' . $clientSessionIdStr;
            // Append the new message to the queue
            $messages = \Illuminate\Support\Facades\Cache::get($cacheKey, []);
            $messages[] = $data;
            \Illuminate\Support\Facades\Cache::put($cacheKey, $messages, 3600);
        }
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
                
                $lastPing = time();
                $lastIndex = 0;
                $cacheKey = 'mcp_messages_' . $sessionId;
                
                // Keep the connection open and poll for messages
                while (true) {
                    // Check for new messages from POST requests. We explicitly use 'file' 
                    // store to prevent locking the SQLite database in an infinite loop!
                    $messages = \Illuminate\Support\Facades\Cache::store('file')->get($cacheKey, []);
                    for ($i = $lastIndex; $i < count($messages); $i++) {
                        echo "event: message\n";
                        echo "data: {$messages[$i]}\n\n";
                        ob_flush();
                        flush();
                    }
                    $lastIndex = count($messages);
                    
                    // Send keepalive pings every 1 second to instantly detect if client disconnected
                    // This forces connection_aborted() to update and frees the FPM worker immediately.
                    if (time() - $lastPing >= 1) {
                        echo ": keepalive\n\n";
                        ob_flush();
                        flush();
                        $lastPing = time();
                    }
                    
                    // Prevent PHP-FPM zombie processes by exiting if client disconnected
                    if (connection_aborted()) {
                        // Clean up messages queue
                        \Illuminate\Support\Facades\Cache::store('file')->forget($cacheKey);
                        break;
                    }
                    
                    sleep(1);
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

        $origin = $this->request->getHeaderLine('Origin') ?: '*';

        if ($method === 'OPTIONS') {
            return response('', 204)
                ->header('Access-Control-Allow-Origin', $origin)
                ->header('Access-Control-Allow-Credentials', 'true')
                ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
                ->header('Access-Control-Allow-Headers', '*');
        }

        if ($method === 'POST') {
            $body = request()->getContent();
            $queryParams = $this->request->getQueryParams();
            $clientSessionIdStr = $queryParams['sessionId'] ?? '';
            
            $jsonBody = json_decode($body, true) ?? [];
            $isInitialize = ($jsonBody['method'] ?? '') === 'initialize';
            
            $internalSessionId = null;

            if ($isInitialize) {
                // The PHP SDK strictly forbids passing a session ID during initialization
                // and internally generates a new one. We pass null to let it generate it.
                if (is_callable($this->messageListener)) {
                    ($this->messageListener)($this, $body, null);
                }
                
                $internalSessionId = $this->sessionId;
                
                if ($internalSessionId && $clientSessionIdStr) {
                    \Illuminate\Support\Facades\Cache::store('file')->put('mcp_session_map_' . $clientSessionIdStr, $internalSessionId->toRfc4122(), 3600);
                }
            } else {
                // For subsequent requests, lookup the internal session ID
                $mappedIdStr = \Illuminate\Support\Facades\Cache::store('file')->get('mcp_session_map_' . $clientSessionIdStr);
                $internalSessionId = $mappedIdStr ? Uuid::fromString($mappedIdStr) : ($clientSessionIdStr ? Uuid::fromString($clientSessionIdStr) : null);
                
                if (is_callable($this->messageListener)) {
                    ($this->messageListener)($this, $body, $internalSessionId);
                }
            }
            
            // Fetch messages queued by the SDK protocol
            $outgoing = $this->getOutgoingMessages($internalSessionId);
            $lastMsg = $this->latestMessage; // Catch immediate errors sent via send()
            
            foreach ($outgoing as $msg) {
                $lastMsg = $msg['message'];
                if ($clientSessionIdStr) {
                    $cacheKey = 'mcp_messages_' . $clientSessionIdStr;
                    $messages = \Illuminate\Support\Facades\Cache::store('file')->get($cacheKey, []);
                    $messages[] = $msg['message'];
                    \Illuminate\Support\Facades\Cache::store('file')->put($cacheKey, $messages, 3600);
                }
            }
            
            if (empty($clientSessionIdStr) && $lastMsg !== null) {
                return response($lastMsg, 200)
                    ->header('Content-Type', 'application/json')
                    ->header('Access-Control-Allow-Origin', $origin)
                    ->header('Access-Control-Allow-Credentials', 'true');
            }
            
            return response()->json(['status' => 'accepted'], 202)
                ->header('Access-Control-Allow-Origin', $origin)
                ->header('Access-Control-Allow-Credentials', 'true');
        }
        
        return response()->json(['error' => 'Method Not Allowed'], 405);
    }
}
