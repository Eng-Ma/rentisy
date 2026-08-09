<?php

namespace App\MCP;

use Mcp\Server\Session\SessionStoreInterface;
use Symfony\Component\Uid\Uuid;
use Illuminate\Support\Facades\Cache;

class LaravelCacheSessionStore implements SessionStoreInterface
{
    private function getKey(Uuid $id): string
    {
        return 'mcp_session_' . $id->toRfc4122();
    }

    public function exists(Uuid $id): bool
    {
        return Cache::has($this->getKey($id));
    }

    public function read(Uuid $id): string|false
    {
        $data = Cache::get($this->getKey($id));
        return $data === null ? false : $data;
    }

    public function write(Uuid $id, string $data): bool
    {
        return Cache::put($this->getKey($id), $data, 3600);
    }

    public function destroy(Uuid $id): bool
    {
        return Cache::forget($this->getKey($id));
    }

    public function gc(): array
    {
        // Cache handles TTL automatically, so no manual GC needed for expiration.
        return [];
    }
}
