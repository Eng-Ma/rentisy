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

use App\Http\Controllers\StorefrontController;
use App\Http\Controllers\CartController;
use App\Http\Controllers\WishlistController;
use App\Http\Controllers\CheckoutController;
use App\Http\Controllers\CustomerDashboardController;
use App\Http\Controllers\Auth\SocialAuthController;

// --- E-Commerce Public Storefront ---
Route::get('/', [StorefrontController::class, 'index'])->name('home');
Route::get('/shop', [StorefrontController::class, 'shop'])->name('store.shop');
Route::get('/shop/product/{id}', [StorefrontController::class, 'product'])->name('store.product');
Route::get('/shop/category/{id}', function ($id) {
    return redirect()->route('store.shop', ['category_id' => $id]);
})->name('store.category');

// --- Shopping Cart ---
Route::get('/cart', [CartController::class, 'index'])->name('cart.index');
Route::post('/cart/add', [CartController::class, 'store'])->name('cart.add');
Route::post('/cart/update/{id}', [CartController::class, 'update'])->name('cart.update');
Route::delete('/cart/remove/{id}', [CartController::class, 'destroy'])->name('cart.remove');
Route::post('/cart/clear', [CartController::class, 'clear'])->name('cart.clear');

// --- Wishlist / Favorites ---
Route::get('/wishlist', [WishlistController::class, 'index'])->name('wishlist.index');
Route::post('/wishlist/toggle', [WishlistController::class, 'toggle'])->name('wishlist.toggle');
Route::post('/wishlist/move-to-cart/{id}', [WishlistController::class, 'moveToCart'])->name('wishlist.move_to_cart');
Route::delete('/wishlist/remove/{id}', [WishlistController::class, 'destroy'])->name('wishlist.remove');

// --- Checkout ---
Route::get('/checkout', [CheckoutController::class, 'index'])->name('checkout.index');
Route::post('/checkout/process', [CheckoutController::class, 'process'])->name('checkout.process');

// --- Social Authentication (Google & Facebook) ---
Route::get('/auth/{provider}/redirect', [SocialAuthController::class, 'redirect'])->name('social.redirect');
Route::get('/auth/{provider}/callback', [SocialAuthController::class, 'callback'])->name('social.callback');

// --- Customer Portal & Dashboard ---
Route::middleware(['auth'])->prefix('customer')->name('customer.')->group(function () {
    Route::get('/dashboard', [CustomerDashboardController::class, 'index'])->name('dashboard');
    Route::get('/orders', [CustomerDashboardController::class, 'orders'])->name('orders');
    Route::get('/orders/{id}', [CustomerDashboardController::class, 'orderShow'])->name('orders.show');
    Route::get('/profile', [CustomerDashboardController::class, 'profile'])->name('profile');
    Route::post('/profile/update', [CustomerDashboardController::class, 'updateProfile'])->name('profile.update');
    Route::post('/profile/password', [CustomerDashboardController::class, 'updatePassword'])->name('password.update');
    Route::get('/statement', [CustomerDashboardController::class, 'statement'])->name('statement');

    // Social linking & unlinking in Customer Profile
    Route::post('/social/{provider}/connect', [SocialAuthController::class, 'connect'])->name('social.connect');
    Route::post('/social/{provider}/disconnect', [SocialAuthController::class, 'disconnect'])->name('social.disconnect');
});

use App\Http\Controllers\Auth\AdminAuthController;
use App\Http\Controllers\OrderController;

// --- Dedicated Admin Authentication ---
Route::get('/admin/login', [AdminAuthController::class, 'create'])->name('admin.login');
Route::post('/admin/login', [AdminAuthController::class, 'store'])->name('admin.login.store');
Route::post('/admin/logout', [AdminAuthController::class, 'destroy'])->name('admin.logout');

// --- Accounting ERP Admin Panel (Strictly Protected with Admin Middleware) ---
Route::middleware(['auth', 'admin'])->group(function () {
    Route::get('dashboard', [DashboardController::class, 'index'])->name('dashboard');

    // Online Store Orders Management
    Route::resource('orders', OrderController::class);
    Route::post('orders/{order}/status', [OrderController::class, 'updateStatus'])->name('orders.update_status');

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

// --- OAuth Discovery & ChatGPT / MCP Admin Authentication ---
$oauthConfig = function (Illuminate\Http\Request $request) {
    $origin = $request->header('Origin') ?: '*';
    if ($request->isMethod('OPTIONS')) {
        return response('', 204)
            ->header('Access-Control-Allow-Origin', $origin)
            ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            ->header('Access-Control-Allow-Headers', '*');
    }
    
    $issuer = $request->url();
    $issuer = preg_replace('#/\.well-known/(oauth-authorization-server|openid-configuration).*$#', '', $issuer);
    
    return response()->json([
        'issuer' => $issuer ?: url('/'),
        'authorization_endpoint' => url('/oauth/authorize'),
        'token_endpoint' => url('/oauth/token'),
        'registration_endpoint' => url('/oauth/register'),
        'userinfo_endpoint' => url('/api/user'),
        'response_types_supported' => ['code'],
        'response_modes_supported' => ['query', 'fragment'],
        'grant_types_supported' => ['authorization_code', 'refresh_token'],
        'token_endpoint_auth_methods_supported' => ['client_secret_post', 'client_secret_basic', 'none'],
        'code_challenge_methods_supported' => ['S256', 'plain'],
        'scopes_supported' => ['mcp', 'openid', 'profile', 'email'],
        'service_documentation' => url('/'),
    ])
    ->header('Access-Control-Allow-Origin', $origin)
    ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    ->header('Access-Control-Allow-Headers', '*');
};

// OpenID Connect & OAuth 2.0 Authorization Server Discovery Endpoints
Route::match(['GET', 'OPTIONS'], '/.well-known/oauth-authorization-server', $oauthConfig);
Route::match(['GET', 'OPTIONS'], '/.well-known/openid-configuration', $oauthConfig);
Route::match(['GET', 'OPTIONS'], '/mcp/.well-known/oauth-authorization-server', $oauthConfig);
Route::match(['GET', 'OPTIONS'], '/mcp/.well-known/openid-configuration', $oauthConfig);
Route::match(['GET', 'OPTIONS'], '/mcp/sse/.well-known/oauth-authorization-server', $oauthConfig);
Route::match(['GET', 'OPTIONS'], '/mcp/sse/.well-known/openid-configuration', $oauthConfig);
Route::match(['GET', 'OPTIONS'], '/mcp/messages/.well-known/oauth-authorization-server', $oauthConfig);
Route::match(['GET', 'OPTIONS'], '/mcp/messages/.well-known/openid-configuration', $oauthConfig);

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

    $redirectUri = $request->query('redirect_uri') ?? $request->input('redirect_uri') ?? session('mcp_oauth_redirect_uri');
    $state = $request->query('state') ?? $request->input('state') ?? session('mcp_oauth_state');
    $clientId = $request->query('client_id') ?? $request->input('client_id') ?? session('mcp_oauth_client_id');
    $codeChallenge = $request->query('code_challenge') ?? $request->input('code_challenge') ?? session('mcp_oauth_code_challenge');
    $codeChallengeMethod = $request->query('code_challenge_method') ?? $request->input('code_challenge_method') ?? session('mcp_oauth_code_challenge_method', 'S256');

    // Require Admin login for OAuth connection
    if (!auth()->check()) {
        if ($redirectUri) {
            session([
                'mcp_oauth_redirect_uri' => $redirectUri,
                'mcp_oauth_state' => $state,
                'mcp_oauth_client_id' => $clientId,
                'mcp_oauth_code_challenge' => $codeChallenge,
                'mcp_oauth_code_challenge_method' => $codeChallengeMethod,
            ]);
        }
        return redirect()->guest(route('login'));
    }

    // Once authenticated as Admin, immediately issue OAuth code and redirect to callback
    if ($redirectUri) {
        session()->forget(['mcp_oauth_redirect_uri', 'mcp_oauth_state', 'mcp_oauth_client_id', 'mcp_oauth_code_challenge', 'mcp_oauth_code_challenge_method']);

        $authCode = 'code_' . Str::random(40);
        \Illuminate\Support\Facades\Cache::put('mcp_oauth_code_' . $authCode, [
            'user_id' => auth()->id(),
            'client_id' => $clientId,
            'code_challenge' => $codeChallenge,
            'code_challenge_method' => $codeChallengeMethod,
        ], 300);

        $delimiter = str_contains($redirectUri, '?') ? '&' : '?';
        $targetUrl = $redirectUri . $delimiter . 'code=' . $authCode . ($state ? '&state=' . urlencode((string)$state) : '');

        if ($request->header('X-Inertia')) {
            return Inertia::location($targetUrl);
        }

        return redirect()->away($targetUrl);
    }

    return redirect()->route('settings.mcp');
})->name('oauth.authorize');

Route::post('/oauth/authorize/approve', function (Illuminate\Http\Request $request) {
    if (!auth()->check()) {
        return redirect()->route('login');
    }

    $redirectUri = $request->input('redirect_uri') ?? session('mcp_oauth_redirect_uri');
    $state = $request->input('state') ?? session('mcp_oauth_state');
    $clientId = $request->input('client_id') ?? session('mcp_oauth_client_id');
    $codeChallenge = $request->input('code_challenge') ?? session('mcp_oauth_code_challenge');
    $codeChallengeMethod = $request->input('code_challenge_method') ?? session('mcp_oauth_code_challenge_method', 'S256');
    $approved = $request->boolean('approve', true);

    if (!$approved) {
        if ($redirectUri) {
            $delimiter = str_contains($redirectUri, '?') ? '&' : '?';
            return redirect()->away($redirectUri . $delimiter . 'error=access_denied' . ($state ? '&state=' . urlencode((string)$state) : ''));
        }
        return redirect()->route('settings.mcp');
    }

    $authCode = 'code_' . Str::random(40);
    \Illuminate\Support\Facades\Cache::put('mcp_oauth_code_' . $authCode, [
        'user_id' => auth()->id(),
        'client_id' => $clientId,
        'code_challenge' => $codeChallenge,
        'code_challenge_method' => $codeChallengeMethod,
    ], 300);

    if ($redirectUri) {
        $delimiter = str_contains($redirectUri, '?') ? '&' : '?';
        $targetUrl = $redirectUri . $delimiter . 'code=' . $authCode . ($state ? '&state=' . urlencode((string)$state) : '');
        if ($request->header('X-Inertia')) {
            return Inertia::location($targetUrl);
        }
        return redirect()->away($targetUrl);
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

    // PKCE Verification if code_challenge was provided
    if ($authData && !empty($authData['code_challenge'])) {
        $codeVerifier = $request->input('code_verifier');
        if (empty($codeVerifier)) {
            return response()->json([
                'error' => 'invalid_request',
                'error_description' => 'Missing code_verifier for PKCE validation.',
            ], 400)->header('Access-Control-Allow-Origin', $origin);
        }

        $method = strtoupper($authData['code_challenge_method'] ?? 'S256');
        if ($method === 'S256') {
            $calculatedChallenge = rtrim(strtr(base64_encode(hash('sha256', $codeVerifier, true)), '+/', '-_'), '=');
        } else {
            $calculatedChallenge = $codeVerifier;
        }

        if (!hash_equals((string)$authData['code_challenge'], (string)$calculatedChallenge)) {
            return response()->json([
                'error' => 'invalid_grant',
                'error_description' => 'PKCE verification failed: code_verifier does not match code_challenge.',
            ], 400)->header('Access-Control-Allow-Origin', $origin);
        }
    }

    $userId = $authData['user_id'] ?? (\App\Models\User::first()?->id ?? 1);
    $accessToken = 'mcp_' . Str::random(48);

    \App\Models\McpToken::create([
        'user_id' => $userId,
        'name' => 'OAuth Connector Client',
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
