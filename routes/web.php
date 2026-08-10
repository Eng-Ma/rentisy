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
        return response('', 204)->header('Access-Control-Allow-Origin', $origin)->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
    }
    
    // Dynamically set issuer to match the requested URL's base to satisfy strict OAuth clients
    $issuer = $request->url();
    if (str_ends_with($issuer, '/.well-known/oauth-authorization-server')) {
        $issuer = substr($issuer, 0, -strlen('/.well-known/oauth-authorization-server'));
    }
    
    return response()->json([
        'issuer' => $issuer ?: url('/'),
        'authorization_endpoint' => url('/oauth/authorize'),
        'token_endpoint' => url('/oauth/token'),
        'registration_endpoint' => url('/oauth/register'),
        'response_types_supported' => ['code'],
        'grant_types_supported' => ['authorization_code'],
    ])->header('Access-Control-Allow-Origin', $origin)->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
};

Route::match(['GET', 'OPTIONS'], '/.well-known/oauth-authorization-server', $oauthConfig);
Route::match(['GET', 'OPTIONS'], '/mcp/sse/.well-known/oauth-authorization-server', $oauthConfig);

Route::match(['POST', 'OPTIONS'], '/oauth/register', function (Illuminate\Http\Request $request) {
    $origin = $request->header('Origin') ?: '*';
    return response()->json([
        'client_id' => 'dummy_mcp_client_id',
        'client_secret' => 'dummy_mcp_client_secret',
    ], 201)->header('Access-Control-Allow-Origin', $origin)->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
});

Route::match(['GET', 'POST', 'OPTIONS'], '/oauth/authorize', function (Illuminate\Http\Request $request) {
    $origin = $request->header('Origin') ?: '*';
    if ($request->isMethod('OPTIONS')) {
        return response('', 204)->header('Access-Control-Allow-Origin', $origin)->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
    }
    $redirectUri = $request->query('redirect_uri');
    $state = $request->query('state');
    // Instantly redirect back with a dummy code
    return redirect()->away($redirectUri . '?code=dummy_mcp_code&state=' . urlencode($state));
});

Route::match(['POST', 'OPTIONS'], '/oauth/token', function (Illuminate\Http\Request $request) {
    $origin = $request->header('Origin') ?: '*';
    if ($request->isMethod('OPTIONS')) {
        return response('', 204)->header('Access-Control-Allow-Origin', $origin)->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
    }
    return response()->json([
        'access_token' => 'dummy_mcp_token',
        'token_type' => 'Bearer',
        'expires_in' => 3600,
    ])->header('Access-Control-Allow-Origin', $origin)->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
});
