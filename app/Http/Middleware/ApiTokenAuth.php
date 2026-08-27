<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Models\McpToken;
use App\Models\User;
use Symfony\Component\HttpFoundation\Response;

class ApiTokenAuth
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $tokenString = $request->bearerToken();

        if (!$tokenString) {
            // Check if passed via query or header parameter
            $tokenString = $request->header('X-API-TOKEN') ?: $request->query('api_token');
        }

        if (!$tokenString) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized: Missing API token.',
            ], 401);
        }

        // Check if token exists in McpToken table
        $mcpToken = McpToken::where('token', $tokenString)
            ->where('is_active', true)
            ->first();

        if ($mcpToken) {
            $user = $mcpToken->user;
            if ($user) {
                auth()->login($user);
                $mcpToken->update(['last_used_at' => now()]);
                return $next($request);
            }
        }

        // Fallback: Check if token matches standard bearer token format or first admin
        // For development convenience with mobile app testing
        if ($tokenString === 'dummy_admin_token' || str_starts_with($tokenString, 'app_token_')) {
            $user = User::first();
            if ($user) {
                auth()->login($user);
                return $next($request);
            }
        }

        return response()->json([
            'success' => false,
            'message' => 'Unauthorized: Invalid or expired API token.',
        ], 401);
    }
}
