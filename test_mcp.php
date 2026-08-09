<?php
$ch = curl_init('https://rantisy.matajir.io/mcp/sse');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, false);
curl_setopt($ch, CURLOPT_WRITEFUNCTION, function($ch, $data) {
    echo "SSE Output: $data\n";
    if (strpos($data, 'sessionId=') !== false) {
        preg_match('/sessionId=([^\s]+)/', $data, $matches);
        if (isset($matches[1])) {
            $sessionId = $matches[1];
            echo "Got Session ID: $sessionId\n";
            
            // Send POST request
            $postCh = curl_init("https://rantisy.matajir.io/mcp/messages?sessionId=" . $sessionId);
            $payload = json_encode([
                "jsonrpc" => "2.0",
                "id" => 1,
                "method" => "initialize",
                "params" => [
                    "protocolVersion" => "2024-11-05",
                    "capabilities" => (object)[],
                    "clientInfo" => [
                        "name" => "test",
                        "version" => "1.0"
                    ]
                ]
            ]);
            curl_setopt($postCh, CURLOPT_POST, 1);
            curl_setopt($postCh, CURLOPT_POSTFIELDS, $payload);
            curl_setopt($postCh, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
            curl_setopt($postCh, CURLOPT_RETURNTRANSFER, true);
            $response = curl_exec($postCh);
            echo "POST Response: $response\n";
            curl_close($postCh);
        }
    }
    return strlen($data);
});
curl_exec($ch);
curl_close($ch);

