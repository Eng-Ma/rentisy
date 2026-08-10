<?php

use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

Route::get('/', function () {
    return Inertia::render('Welcome');
})->name('home');

use App\Http\Controllers\AccountController;
use App\Http\Controllers\JournalEntryController;
use App\Http\Controllers\ItemController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\StoreController;

Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('dashboard', [App\Http\Controllers\DashboardController::class, 'index'])->name('dashboard');

    Route::resource('accounts', AccountController::class);
    Route::resource('journal-entries', JournalEntryController::class);
    
    // Inventory
    Route::resource('items', ItemController::class);
    Route::resource('categories', CategoryController::class);
    Route::resource('stores', StoreController::class);

    // Sales & Purchases
    Route::resource('parties', App\Http\Controllers\PartyController::class);
    Route::resource('invoices', App\Http\Controllers\InvoiceController::class);

    // Reports
    Route::get('reports', [App\Http\Controllers\ReportController::class, 'index'])->name('reports.index');
    Route::get('reports/account-statement', [App\Http\Controllers\ReportController::class, 'accountStatement'])->name('reports.account_statement');
    Route::get('reports/trial-balance', [App\Http\Controllers\ReportController::class, 'trialBalance'])->name('reports.trial_balance');
    Route::get('reports/income-statement', [App\Http\Controllers\ReportController::class, 'incomeStatement'])->name('reports.income_statement');
    Route::get('reports/party-statement', [App\Http\Controllers\ReportController::class, 'partyReport'])->name('reports.party_statement');
});

require __DIR__.'/settings.php';
require __DIR__.'/auth.php';

// MCP Endpoints
Route::match(['GET', 'POST', 'OPTIONS'], '/mcp/sse', [\App\Http\Controllers\McpController::class, 'handle'])->name('mcp.sse');
Route::match(['GET', 'POST', 'OPTIONS'], '/mcp/messages', [\App\Http\Controllers\McpController::class, 'handle'])->name('mcp.messages');

$oauthConfig = function (Illuminate\Http\Request $request) {
    $origin = $request->header('Origin') ?: '*';
    if ($request->isMethod('OPTIONS')) {
        return response('', 204)
            ->header('Access-Control-Allow-Origin', $origin)
            ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            ->header('Access-Control-Allow-Headers', '*');
    }
    
    $baseUrl = url('/');
    return response()->json([
        'issuer' => $baseUrl,
        'authorization_endpoint' => url('/oauth/authorize'),
        'token_endpoint' => url('/oauth/token'),
        'registration_endpoint' => url('/oauth/register'),
        'response_types_supported' => ['code'],
        'grant_types_supported' => ['authorization_code'],
        'scopes_supported' => ['mcp'],
        'token_endpoint_auth_methods_supported' => ['client_secret_basic', 'client_secret_post', 'none'],
    ])->header('Access-Control-Allow-Origin', $origin)
      ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ->header('Access-Control-Allow-Headers', '*');
};

$protectedResourceConfig = function (Illuminate\Http\Request $request) {
    $origin = $request->header('Origin') ?: '*';
    if ($request->isMethod('OPTIONS')) {
        return response('', 204)
            ->header('Access-Control-Allow-Origin', $origin)
            ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            ->header('Access-Control-Allow-Headers', '*');
    }
    return response()->json([
        'resource' => url('/mcp/sse'),
        'authorization_servers' => [url('/')],
    ])->header('Access-Control-Allow-Origin', $origin)
      ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ->header('Access-Control-Allow-Headers', '*');
};

Route::match(['GET', 'OPTIONS'], '/.well-known/oauth-authorization-server', $oauthConfig);
Route::match(['GET', 'OPTIONS'], '/mcp/sse/.well-known/oauth-authorization-server', $oauthConfig);
Route::match(['GET', 'OPTIONS'], '/.well-known/openid-configuration', $oauthConfig);
Route::match(['GET', 'OPTIONS'], '/mcp/sse/.well-known/openid-configuration', $oauthConfig);

Route::match(['GET', 'OPTIONS'], '/.well-known/oauth-protected-resource', $protectedResourceConfig);
Route::match(['GET', 'OPTIONS'], '/mcp/sse/.well-known/oauth-protected-resource', $protectedResourceConfig);

Route::match(['POST', 'OPTIONS'], '/oauth/register', function (Illuminate\Http\Request $request) {
    $origin = $request->header('Origin') ?: '*';
    if ($request->isMethod('OPTIONS')) {
        return response('', 204)
            ->header('Access-Control-Allow-Origin', $origin)
            ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            ->header('Access-Control-Allow-Headers', '*');
    }
    return response()->json([
        'client_id' => 'dummy_mcp_client_id',
        'client_secret' => 'dummy_mcp_client_secret',
        'client_id_issued_at' => time(),
        'client_secret_expires_at' => 0,
    ], 201)
    ->header('Access-Control-Allow-Origin', $origin)
    ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    ->header('Access-Control-Allow-Headers', '*');
});

Route::match(['GET', 'POST', 'OPTIONS'], '/oauth/authorize', function (Illuminate\Http\Request $request) {
    $origin = $request->header('Origin') ?: '*';
    if ($request->isMethod('OPTIONS')) {
        return response('', 204)
            ->header('Access-Control-Allow-Origin', $origin)
            ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            ->header('Access-Control-Allow-Headers', '*');
    }
    $redirectUri = $request->query('redirect_uri') ?: $request->input('redirect_uri');
    $state = $request->query('state') ?: $request->input('state');
    
    if (!$redirectUri) {
        return response()->json(['error' => 'invalid_request', 'error_description' => 'Missing redirect_uri'], 400);
    }

    $separator = str_contains($redirectUri, '?') ? '&' : '?';
    $targetUrl = $redirectUri . $separator . 'code=dummy_mcp_code';
    if ($state) {
        $targetUrl .= '&state=' . urlencode((string)$state);
    }
    
    return redirect()->away($targetUrl)->header('Access-Control-Allow-Origin', $origin);
});

Route::match(['POST', 'OPTIONS'], '/oauth/token', function (Illuminate\Http\Request $request) {
    $origin = $request->header('Origin') ?: '*';
    if ($request->isMethod('OPTIONS')) {
        return response('', 204)
            ->header('Access-Control-Allow-Origin', $origin)
            ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            ->header('Access-Control-Allow-Headers', '*');
    }
    return response()->json([
        'access_token' => 'dummy_mcp_token',
        'token_type' => 'Bearer',
        'expires_in' => 86400,
    ])
    ->header('Access-Control-Allow-Origin', $origin)
    ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    ->header('Access-Control-Allow-Headers', '*');
});
