<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;
use Inertia\Inertia;
use Illuminate\Support\Str;

class AuthenticatedSessionController extends Controller
{
    /**
     * Show the login page.
     */
    public function create(Request $request)
    {
        return Inertia::render('auth/Login', [
            'canResetPassword' => Route::has('password.request'),
            'status' => $request->session()->get('status'),
        ]);
    }

    /**
     * Handle an incoming authentication request.
     */
    public function store(LoginRequest $request)
    {
        // Preserve OAuth session variables before regeneration
        $redirectUri = session('mcp_oauth_redirect_uri');
        $state = session('mcp_oauth_state');
        $clientId = session('mcp_oauth_client_id');

        $request->authenticate();

        $request->session()->regenerate();

        // If this login originated from ChatGPT OAuth, immediately redirect back to ChatGPT
        if ($redirectUri) {
            session()->forget(['mcp_oauth_redirect_uri', 'mcp_oauth_state', 'mcp_oauth_client_id']);

            $authCode = 'code_' . Str::random(40);
            \Illuminate\Support\Facades\Cache::put('mcp_oauth_code_' . $authCode, [
                'user_id' => auth()->id(),
                'client_id' => $clientId,
            ], 300);

            $delimiter = str_contains($redirectUri, '?') ? '&' : '?';
            $targetUrl = $redirectUri . $delimiter . 'code=' . $authCode . ($state ? '&state=' . urlencode($state) : '');

            return Inertia::location($targetUrl);
        }

        return redirect()->intended(route('dashboard', absolute: false));
    }

    /**
     * Destroy an authenticated session.
     */
    public function destroy(Request $request)
    {
        Auth::guard('web')->logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/');
    }
}
