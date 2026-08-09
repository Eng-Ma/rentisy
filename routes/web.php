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
Route::get('/mcp/sse', [\App\Http\Controllers\McpController::class, 'handle'])->name('mcp.sse');
Route::match(['GET', 'POST', 'OPTIONS'], '/mcp/messages', [\App\Http\Controllers\McpController::class, 'handle'])->name('mcp.messages');

// Dummy OAuth routes to satisfy Claude Web / Custom Actions MCP registration
Route::match(['GET', 'OPTIONS'], '/.well-known/oauth-authorization-server', function () {
    return response()->json([
        "issuer" => "https://rantisy.matajir.io",
        "authorization_endpoint" => "https://rantisy.matajir.io/oauth/authorize",
        "token_endpoint" => "https://rantisy.matajir.io/oauth/token",
        "registration_endpoint" => "https://rantisy.matajir.io/oauth/register",
        "scopes_supported" => ["mcp"],
        "response_types_supported" => ["code"],
        "grant_types_supported" => ["authorization_code", "refresh_token"],
        "token_endpoint_auth_methods_supported" => ["none", "client_secret_post"]
    ])->header('Access-Control-Allow-Origin', '*')->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
});

Route::match(['POST', 'OPTIONS'], '/oauth/register', function () {
    return response()->json([
        "client_id" => "dummy_client_" . uniqid(),
        "client_secret" => "dummy_secret"
    ], 201)->header('Access-Control-Allow-Origin', '*')->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
});

Route::match(['GET', 'POST', 'OPTIONS'], '/oauth/authorize', function (Illuminate\Http\Request $request) {
    if ($request->isMethod('OPTIONS')) {
        return response('', 204)->header('Access-Control-Allow-Origin', '*')->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
    }
    $redirectUri = $request->query('redirect_uri');
    $state = $request->query('state');
    
    return redirect()->away($redirectUri . '?code=dummy_auth_code&state=' . $state);
});

Route::match(['POST', 'OPTIONS'], '/oauth/token', function () {
    return response()->json([
        "access_token" => "dummy_access_token",
        "token_type" => "Bearer",
        "expires_in" => 3600,
        "refresh_token" => "dummy_refresh_token"
    ])->header('Access-Control-Allow-Origin', '*')->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
});
