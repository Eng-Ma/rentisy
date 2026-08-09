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
Route::get('/.well-known/oauth-authorization-server', function () {
    return response()->json([
        'issuer' => url('/'),
        'authorization_endpoint' => url('/oauth/authorize'),
        'token_endpoint' => url('/oauth/token'),
        'registration_endpoint' => url('/oauth/register'),
        'response_types_supported' => ['code'],
        'grant_types_supported' => ['authorization_code'],
    ]);
});

Route::post('/oauth/register', function () {
    return response()->json([
        'client_id' => 'dummy_mcp_client_id',
        'client_secret' => 'dummy_mcp_client_secret',
    ], 201);
});

Route::get('/oauth/authorize', function (\Illuminate\Http\Request $request) {
    $redirectUri = $request->query('redirect_uri');
    $state = $request->query('state');
    // Instantly redirect back with a dummy code
    return redirect()->away($redirectUri . '?code=dummy_mcp_code&state=' . urlencode($state));
});

Route::post('/oauth/token', function () {
    return response()->json([
        'access_token' => 'dummy_mcp_access_token',
        'token_type' => 'Bearer',
        'expires_in' => 31536000,
    ]);
});
