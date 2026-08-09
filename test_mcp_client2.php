<?php
$sseUrl = "https://rantisy.matajir.io/mcp/sse";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $sseUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$endpoint = null;

// Read stream
curl_setopt($ch, CURLOPT_WRITEFUNCTION, function($ch, $data) use (&$endpoint) {
    if (!$endpoint && preg_match('/data: (.*mcp\/messages\?sessionId=[a-zA-Z0-9\-]+)/', $data, $matches)) {
        $endpoint = trim($matches[1]);
        
        // Send initialize
        sendPost($endpoint, [
            "jsonrpc" => "2.0",
            "method" => "initialize",
            "params" => [
                "protocolVersion" => "2024-11-05",
                "capabilities" => [],
                "clientInfo" => ["name" => "test", "version" => "1.0"]
            ],
            "id" => 1
        ]);
        
        // Send getInvoices
        sendPost($endpoint, [
            "jsonrpc" => "2.0",
            "method" => "tools/call",
            "params" => [
                "name" => "getInvoices",
                "arguments" => ["type" => "bill"]
            ],
            "id" => 2
        ]);
        
        return strlen($data);
    }
    
    // Check if the data contains the getInvoices result
    if (strpos($data, '"id":2') !== false) {
        if (preg_match('/data: (.*)\n\n/s', $data, $matches)) {
            echo "BILLS RESULT:\n" . $matches[1] . "\n";
            return 0; // Abort stream
        }
    }
    
    return strlen($data);
});

function sendPost($url, $payload) {
    $c = curl_init();
    curl_setopt($c, CURLOPT_URL, $url);
    curl_setopt($c, CURLOPT_POST, true);
    curl_setopt($c, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($c, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($c, CURLOPT_RETURNTRANSFER, true);
    curl_exec($c);
    curl_close($c);
}

@curl_exec($ch);
curl_close($ch);
