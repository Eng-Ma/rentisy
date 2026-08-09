<?php
require 'vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Mcp\Server;
use App\MCP\LaravelSseTransport;

// Mock PSR-7 Request
$request = new \GuzzleHttp\Psr7\ServerRequest(
    'POST', 
    '/mcp/sse', 
    ['Content-Type' => 'application/json'], 
    '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}'
);

$server = Server::builder()
    ->setServerInfo('Laravel-Accounting-MCP', '1.0.0')
    ->build();

$transport = new LaravelSseTransport($request);
$response = $server->run($transport);

echo "HTTP Status: " . $response->getStatusCode() . "\n";
echo "Response Body:\n" . $response->getContent() . "\n";
