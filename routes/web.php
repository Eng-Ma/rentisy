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
