<?php
$sseUrl = "https://rantisy.matajir.io/mcp/sse";

// 1. Start SSE stream to get endpoint and sessionId
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $sseUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
// We only need the first few lines to get the endpoint
curl_setopt($ch, CURLOPT_WRITEFUNCTION, function($ch, $data) use (&$endpoint) {
    if (preg_match('/data: (.*mcp\/messages\?sessionId=[a-zA-Z0-9\-]+)/', $data, $matches)) {
        $endpoint = trim($matches[1]);
        return 0; // Abort after finding it
    }
    return strlen($data);
});
@curl_exec($ch);
curl_close($ch);

if (!$endpoint) {
    die("Failed to get endpoint\n");
}

echo "Got endpoint: $endpoint\n";

function sendPost($url, $payload) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $result = curl_exec($ch);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return [$status, $result];
}

// 2. Send initialize
$initPayload = [
    "jsonrpc" => "2.0",
    "method" => "initialize",
    "params" => [
        "protocolVersion" => "2024-11-05",
        "capabilities" => [],
        "clientInfo" => ["name" => "test", "version" => "1.0"]
    ],
    "id" => 1
];
list($status, $result) = sendPost($endpoint, $initPayload);
echo "Initialize POST returned HTTP $status\n";

// 3. Send tools/call for get_invoices
$callPayload = [
    "jsonrpc" => "2.0",
    "method" => "tools/call",
    "params" => [
        "name" => "get_invoices",
        "arguments" => ["type" => "bill"]
    ],
    "id" => 2
];
list($status, $result) = sendPost($endpoint, $callPayload);
echo "Tools/call POST returned HTTP $status\n";

// To get the actual response, we would need to read the SSE stream.
// Since we aborted the SSE stream, let's just query the server's cache directly
// since we have access to the local codebase (wait, local codebase cache is not live server cache).
// Actually, since I fixed HTTP clients, we can just omit the sessionId to get the immediate response!
