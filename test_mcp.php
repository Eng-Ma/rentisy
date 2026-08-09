<?php
$sessionId = json_decode(file_get_contents('https://rantisy.matajir.io/mcp/sse'));
// Actually, file_get_contents doesn't work well for SSE.
