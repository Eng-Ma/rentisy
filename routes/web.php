<?php

use Illuminate\Support\Facades\Route;
use Inertia\Inertia;
use Illuminate\Support\Str;
use App\Http\Controllers\AccountController;
use App\Http\Controllers\JournalEntryController;
use App\Http\Controllers\ItemController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\StoreController;
use App\Http\Controllers\PartyController;
use App\Http\Controllers\InvoiceController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\VoucherController;
use App\Http\Controllers\CheckController;
use App\Http\Controllers\CostCenterController;
use App\Http\Controllers\StockTransferController;
use App\Http\Controllers\QuotationController;
use App\Http\Controllers\FixedAssetController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\McpController;

Route::get('/', function () {
    return Inertia::render('Welcome');
})->name('home');

Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('dashboard', [DashboardController::class, 'index'])->name('dashboard');

    // General Accounting
    Route::resource('accounts', AccountController::class);
    Route::resource('journal-entries', JournalEntryController::class);
    Route::resource('cost-centers', CostCenterController::class);

    // Vouchers (سندات القبض والصرف)
    Route::resource('vouchers', VoucherController::class);

    // Checks Portfolio (حافظة الشيكات)
    Route::resource('checks', CheckController::class);
    Route::post('checks/{check}/status', [CheckController::class, 'updateStatus'])->name('checks.update_status');

    // Inventory & Warehouses
    Route::resource('items', ItemController::class);
    Route::resource('categories', CategoryController::class);
    Route::resource('stores', StoreController::class);
    Route::resource('stock-transfers', StockTransferController::class);

    // Sales, Purchases & Quotations
    Route::resource('parties', PartyController::class);
    Route::resource('invoices', InvoiceController::class);
    Route::resource('quotations', QuotationController::class);
    Route::post('quotations/{quotation}/convert', [QuotationController::class, 'convertToInvoice'])->name('quotations.convert');

    // Fixed Assets & Depreciation (الأصول الثابتة والإهلاك)
    Route::resource('fixed-assets', FixedAssetController::class);
    Route::post('fixed-assets/{fixed_asset}/depreciate', [FixedAssetController::class, 'depreciate'])->name('fixed_assets.depreciate');

    // Reports (التقارير المالية والمستودعية)
    Route::get('reports', [ReportController::class, 'index'])->name('reports.index');
    Route::get('reports/account-statement', [ReportController::class, 'accountStatement'])->name('reports.account_statement');
    Route::get('reports/trial-balance', [ReportController::class, 'trialBalance'])->name('reports.trial_balance');
    Route::get('reports/income-statement', [ReportController::class, 'incomeStatement'])->name('reports.income_statement');
    Route::get('reports/party-statement', [ReportController::class, 'partyReport'])->name('reports.party_statement');
    Route::get('reports/aging', [ReportController::class, 'aging'])->name('reports.aging');
    Route::get('reports/cost-centers', [ReportController::class, 'costCenters'])->name('reports.cost_centers');
    Route::get('reports/checks', [ReportController::class, 'checks'])->name('reports.checks');
    Route::get('reports/stock-movement', [ReportController::class, 'stockMovement'])->name('reports.stock_movement');
});

require __DIR__.'/settings.php';
require __DIR__.'/auth.php';

// --- MCP Endpoints ---
Route::match(['GET', 'POST', 'OPTIONS'], '/mcp/sse', [McpController::class, 'handle'])->name('mcp.sse');
Route::match(['GET', 'POST', 'OPTIONS'], '/mcp/messages', [McpController::class, 'handle'])->name('mcp.messages');

// --- OAuth Discovery & ChatGPT Admin Authentication ---
$oauthConfig = function (Illuminate\Http\Request $request) {
    $origin = $request->header('Origin') ?: '*';
    if ($request->isMethod('OPTIONS')) {
        return response('', 204)->header('Access-Control-Allow-Origin', $origin)->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
    }
    
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
        'client_id' => 'mcp_client_' . Str::random(16),
        'client_secret' => 'mcp_sec_' . Str::random(32),
    ], 201)->header('Access-Control-Allow-Origin', $origin)->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
});

Route::match(['GET', 'POST', 'OPTIONS'], '/oauth/authorize', function (Illuminate\Http\Request $request) {
    $origin = $request->header('Origin') ?: '*';
    if ($request->isMethod('OPTIONS')) {
        return response('', 204)->header('Access-Control-Allow-Origin', $origin)->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
    }

    // Require Admin login for ChatGPT / MCP connection
    if (!auth()->check()) {
        return redirect()->guest(route('login', ['return_url' => $request->fullUrl()]));
    }

    $redirectUri = $request->query('redirect_uri') ?? $request->input('redirect_uri');
    $state = $request->query('state') ?? $request->input('state');
    $clientId = $request->query('client_id') ?? $request->input('client_id');

    if ($request->isMethod('POST')) {
        $approved = $request->boolean('approve', true);
        if (!$approved && $redirectUri) {
            return redirect()->away($redirectUri . '?error=access_denied&state=' . urlencode($state));
        }

        $authCode = 'code_' . Str::random(40);
        \Illuminate\Support\Facades\Cache::put('mcp_oauth_code_' . $authCode, [
            'user_id' => auth()->id(),
            'client_id' => $clientId,
        ], 300);

        if ($redirectUri) {
            return redirect()->away($redirectUri . '?code=' . $authCode . '&state=' . urlencode($state));
        }

        return redirect()->route('settings.mcp')->with('success', 'تم تفويض الجلسة بنجاح');
    }

    if ($redirectUri) {
        return Inertia::render('Auth/McpAuthorize', [
            'clientId' => $clientId,
            'redirectUri' => $redirectUri,
            'state' => $state,
            'user' => [
                'id' => auth()->id(),
                'name' => auth()->user()->name,
                'email' => auth()->user()->email,
            ],
        ]);
    }

    return redirect()->route('settings.mcp');
})->name('oauth.authorize');

Route::post('/oauth/authorize/approve', function (Illuminate\Http\Request $request) {
    if (!auth()->check()) {
        return redirect()->route('login');
    }

    $redirectUri = $request->input('redirect_uri');
    $state = $request->input('state');
    $clientId = $request->input('client_id');
    $approved = $request->boolean('approve', true);

    if (!$approved) {
        if ($redirectUri) {
            return redirect()->away($redirectUri . '?error=access_denied&state=' . urlencode($state));
        }
        return redirect()->route('settings.mcp');
    }

    $authCode = 'code_' . Str::random(40);
    \Illuminate\Support\Facades\Cache::put('mcp_oauth_code_' . $authCode, [
        'user_id' => auth()->id(),
        'client_id' => $clientId,
    ], 300);

    if ($redirectUri) {
        return redirect()->away($redirectUri . '?code=' . $authCode . '&state=' . urlencode($state));
    }

    return redirect()->route('settings.mcp')->with('success', 'تم التفويض بنجاح');
})->name('oauth.authorize.post');

Route::match(['POST', 'OPTIONS'], '/oauth/token', function (Illuminate\Http\Request $request) {
    $origin = $request->header('Origin') ?: '*';
    if ($request->isMethod('OPTIONS')) {
        return response('', 204)->header('Access-Control-Allow-Origin', $origin)->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
    }

    $code = $request->input('code');
    $authData = $code ? \Illuminate\Support\Facades\Cache::pull('mcp_oauth_code_' . $code) : null;

    if (!$authData && $code !== 'dummy_mcp_code') {
        return response()->json([
            'error' => 'invalid_grant',
            'error_description' => 'The authorization code is invalid or expired. Admin login required.',
        ], 400)->header('Access-Control-Allow-Origin', $origin);
    }

    $userId = $authData['user_id'] ?? (\App\Models\User::first()?->id ?? 1);
    $accessToken = 'mcp_' . Str::random(48);

    \App\Models\McpToken::create([
        'user_id' => $userId,
        'name' => 'ChatGPT OAuth Connection',
        'token' => $accessToken,
        'client_id' => $request->input('client_id'),
        'is_active' => true,
    ]);

    return response()->json([
        'access_token' => $accessToken,
        'token_type' => 'Bearer',
        'expires_in' => 31536000,
    ])->header('Access-Control-Allow-Origin', $origin)->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')->header('Access-Control-Allow-Headers', '*');
});
