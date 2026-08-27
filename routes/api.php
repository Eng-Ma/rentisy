<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardApiController;
use App\Http\Controllers\Api\AccountApiController;
use App\Http\Controllers\Api\JournalEntryApiController;
use App\Http\Controllers\Api\VoucherApiController;
use App\Http\Controllers\Api\CheckApiController;
use App\Http\Controllers\Api\ItemApiController;
use App\Http\Controllers\Api\StockTransferApiController;
use App\Http\Controllers\Api\PartyApiController;
use App\Http\Controllers\Api\InvoiceApiController;
use App\Http\Controllers\Api\QuotationApiController;
use App\Http\Controllers\Api\FixedAssetApiController;
use App\Http\Controllers\Api\CostCenterApiController;
use App\Http\Controllers\Api\ReportApiController;
use App\Http\Controllers\Api\AiDatabaseApiController;
use App\Http\Middleware\ApiTokenAuth;

// Public Auth routes
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);

// Protected API routes
Route::middleware([ApiTokenAuth::class])->group(function () {
    // Current User & Logout
    Route::get('/user', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Dashboard
    Route::get('/dashboard', [DashboardApiController::class, 'index']);

    // General Accounting & Accounts
    Route::get('/accounts', [AccountApiController::class, 'index']);
    Route::post('/accounts', [AccountApiController::class, 'store']);
    Route::get('/accounts/{account}', [AccountApiController::class, 'show']);
    Route::put('/accounts/{account}', [AccountApiController::class, 'update']);
    Route::delete('/accounts/{account}', [AccountApiController::class, 'destroy']);
    Route::get('/currencies', [AccountApiController::class, 'currencies']);

    // Journal Entries
    Route::get('/journal-entries', [JournalEntryApiController::class, 'index']);
    Route::post('/journal-entries', [JournalEntryApiController::class, 'store']);
    Route::get('/journal-entries/{journalEntry}', [JournalEntryApiController::class, 'show']);
    Route::delete('/journal-entries/{journalEntry}', [JournalEntryApiController::class, 'destroy']);

    // Cost Centers
    Route::get('/cost-centers', [CostCenterApiController::class, 'index']);
    Route::post('/cost-centers', [CostCenterApiController::class, 'store']);
    Route::get('/cost-centers/{costCenter}', [CostCenterApiController::class, 'show']);
    Route::put('/cost-centers/{costCenter}', [CostCenterApiController::class, 'update']);
    Route::delete('/cost-centers/{costCenter}', [CostCenterApiController::class, 'destroy']);

    // Vouchers (سندات القبض والصرف)
    Route::get('/vouchers', [VoucherApiController::class, 'index']);
    Route::post('/vouchers', [VoucherApiController::class, 'store']);
    Route::get('/vouchers/{voucher}', [VoucherApiController::class, 'show']);
    Route::delete('/vouchers/{voucher}', [VoucherApiController::class, 'destroy']);

    // Checks Portfolio (حافظة الشيكات)
    Route::get('/checks', [CheckApiController::class, 'index']);
    Route::post('/checks', [CheckApiController::class, 'store']);
    Route::get('/checks/{check}', [CheckApiController::class, 'show']);
    Route::post('/checks/{check}/status', [CheckApiController::class, 'updateStatus']);
    Route::delete('/checks/{check}', [CheckApiController::class, 'destroy']);

    // Inventory, Items, Categories, Stores
    Route::get('/items', [ItemApiController::class, 'index']);
    Route::post('/items', [ItemApiController::class, 'store']);
    Route::get('/items/{item}', [ItemApiController::class, 'show']);
    Route::put('/items/{item}', [ItemApiController::class, 'update']);
    Route::delete('/items/{item}', [ItemApiController::class, 'destroy']);
    Route::get('/categories', [ItemApiController::class, 'categories']);
    Route::post('/categories', [ItemApiController::class, 'storeCategory']);
    Route::get('/stores', [ItemApiController::class, 'stores']);
    Route::post('/stores', [ItemApiController::class, 'storeStore']);

    // Stock Transfers (مناقلات وتعديل المخزون)
    Route::get('/stock-transfers', [StockTransferApiController::class, 'index']);
    Route::post('/stock-transfers', [StockTransferApiController::class, 'store']);
    Route::get('/stock-transfers/{stockTransfer}', [StockTransferApiController::class, 'show']);
    Route::delete('/stock-transfers/{stockTransfer}', [StockTransferApiController::class, 'destroy']);

    // Parties (Customers & Vendors)
    Route::get('/parties', [PartyApiController::class, 'index']);
    Route::post('/parties', [PartyApiController::class, 'store']);
    Route::get('/parties/{party}', [PartyApiController::class, 'show']);
    Route::put('/parties/{party}', [PartyApiController::class, 'update']);
    Route::delete('/parties/{party}', [PartyApiController::class, 'destroy']);

    // Invoices (Sales, Purchases, Returns)
    Route::get('/invoices', [InvoiceApiController::class, 'index']);
    Route::post('/invoices', [InvoiceApiController::class, 'store']);
    Route::get('/invoices/{invoice}', [InvoiceApiController::class, 'show']);
    Route::delete('/invoices/{invoice}', [InvoiceApiController::class, 'destroy']);

    // Quotations (عروض الأسعار)
    Route::get('/quotations', [QuotationApiController::class, 'index']);
    Route::post('/quotations', [QuotationApiController::class, 'store']);
    Route::get('/quotations/{quotation}', [QuotationApiController::class, 'show']);
    Route::post('/quotations/{quotation}/convert', [QuotationApiController::class, 'convertToInvoice']);
    Route::delete('/quotations/{quotation}', [QuotationApiController::class, 'destroy']);

    // Fixed Assets & Depreciation (الأصول الثابتة والإهلاك)
    Route::get('/fixed-assets', [FixedAssetApiController::class, 'index']);
    Route::post('/fixed-assets', [FixedAssetApiController::class, 'store']);
    Route::get('/fixed-assets/{fixedAsset}', [FixedAssetApiController::class, 'show']);
    Route::post('/fixed-assets/{fixedAsset}/depreciate', [FixedAssetApiController::class, 'depreciate']);
    Route::delete('/fixed-assets/{fixedAsset}', [FixedAssetApiController::class, 'destroy']);

    // Al-Aseel Financial & Warehouse Reports
    Route::get('/reports/account-statement', [ReportApiController::class, 'accountStatement']);
    Route::get('/reports/trial-balance', [ReportApiController::class, 'trialBalance']);
    Route::get('/reports/income-statement', [ReportApiController::class, 'incomeStatement']);
    Route::get('/reports/party-statement', [ReportApiController::class, 'partyStatement']);
    Route::get('/reports/aging', [ReportApiController::class, 'aging']);
    Route::get('/reports/cost-centers', [ReportApiController::class, 'costCenters']);
    Route::get('/reports/checks', [ReportApiController::class, 'checks']);
    Route::get('/reports/stock-movement', [ReportApiController::class, 'stockMovement']);

    // Direct AI Database Superpowers (Direct SQL, Schema, Global Search)
    Route::get('/ai/schema', [AiDatabaseApiController::class, 'schema']);
    Route::post('/ai/query', [AiDatabaseApiController::class, 'executeQuery']);
    Route::post('/ai/search', [AiDatabaseApiController::class, 'globalSearch']);
});
