<?php

namespace App\Http\Controllers;

use App\Models\FixedAsset;
use App\Models\AssetDepreciation;
use App\Models\Account;
use App\Models\CostCenter;
use App\Models\JournalEntry;
use App\Models\Currency;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class FixedAssetController extends Controller
{
    public function index()
    {
        $assets = FixedAsset::with(['assetAccount', 'depreciationExpenseAccount', 'accumulatedDepreciationAccount', 'costCenter', 'depreciations'])
            ->orderBy('id', 'desc')
            ->get();

        $accounts = Account::where('is_active', true)->get();
        $costCenters = CostCenter::where('is_active', true)->get();

        return Inertia::render('FixedAssets/Index', [
            'assets' => $assets,
            'accounts' => $accounts,
            'costCenters' => $costCenters,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'code' => 'required|string|unique:fixed_assets,code',
            'name' => 'required|string|max:255',
            'purchase_date' => 'required|date',
            'purchase_cost' => 'required|numeric|min:0.01',
            'salvage_value' => 'nullable|numeric|min:0',
            'useful_life_years' => 'required|numeric|min:0.1',
            'depreciation_rate' => 'nullable|numeric|min:0',
            'asset_account_id' => 'nullable|exists:accounts,id',
            'depreciation_expense_account_id' => 'nullable|exists:accounts,id',
            'accumulated_depreciation_account_id' => 'nullable|exists:accounts,id',
            'cost_center_id' => 'nullable|exists:cost_centers,id',
            'notes' => 'nullable|string',
        ]);

        $purchaseCost = (float)$validated['purchase_cost'];
        $salvageValue = (float)($validated['salvage_value'] ?? 0);
        $usefulLife = (float)$validated['useful_life_years'];

        $depreciationRate = $validated['depreciation_rate'] ?? ($usefulLife > 0 ? (100 / $usefulLife) : 20);

        FixedAsset::create([
            'code' => $validated['code'],
            'name' => $validated['name'],
            'purchase_date' => $validated['purchase_date'],
            'purchase_cost' => $purchaseCost,
            'salvage_value' => $salvageValue,
            'useful_life_years' => $usefulLife,
            'depreciation_rate' => $depreciationRate,
            'depreciation_method' => 'straight_line',
            'asset_account_id' => $validated['asset_account_id'] ?? null,
            'depreciation_expense_account_id' => $validated['depreciation_expense_account_id'] ?? null,
            'accumulated_depreciation_account_id' => $validated['accumulated_depreciation_account_id'] ?? null,
            'cost_center_id' => $validated['cost_center_id'] ?? null,
            'total_depreciated' => 0,
            'current_book_value' => $purchaseCost,
            'is_active' => true,
            'notes' => $validated['notes'] ?? null,
        ]);

        return redirect()->route('fixed-assets.index')->with('success', 'تم تسجيل الأصل الثابت بنجاح');
    }

    public function depreciate(Request $request, FixedAsset $fixedAsset)
    {
        $validated = $request->validate([
            'date' => 'required|date',
            'amount' => 'nullable|numeric|min:0.01',
            'notes' => 'nullable|string',
        ]);

        $depreciationAmount = $validated['amount'] ?? null;

        if (!$depreciationAmount) {
            // Default yearly / period depreciation = (cost - salvage) * (rate / 100)
            $depreciableBase = max(0, $fixedAsset->purchase_cost - $fixedAsset->salvage_value);
            $depreciationAmount = round(($depreciableBase * ($fixedAsset->depreciation_rate / 100)), 2);
        }

        if ($fixedAsset->current_book_value - $depreciationAmount < $fixedAsset->salvage_value) {
            $depreciationAmount = max(0, $fixedAsset->current_book_value - $fixedAsset->salvage_value);
        }

        if ($depreciationAmount <= 0) {
            return back()->with('error', 'تم استهلاك الأصل بالكامل أو وصل إلى القيمة التخريدية.');
        }

        DB::transaction(function () use ($fixedAsset, $validated, $depreciationAmount) {
            $currency = Currency::where('is_default', true)->first() ?? Currency::first();
            $expenseAcc = $fixedAsset->depreciation_expense_account_id ?? Account::where('code', '5201')->first()?->id;
            $accumulatedAcc = $fixedAsset->accumulated_depreciation_account_id ?? $fixedAsset->asset_account_id;

            $entry = null;
            if ($expenseAcc && $accumulatedAcc && $currency) {
                $entry = JournalEntry::create([
                    'date' => $validated['date'],
                    'reference' => 'DEP-' . $fixedAsset->code,
                    'description' => "قيد إهلاك أصل ثابت: {$fixedAsset->name} ({$fixedAsset->code})",
                    'currency_id' => $currency->id,
                    'exchange_rate' => 1.0,
                ]);

                // Debit: Depreciation Expense
                $entry->lines()->create([
                    'account_id' => $expenseAcc,
                    'cost_center_id' => $fixedAsset->cost_center_id,
                    'description' => "مصروف إهلاك {$fixedAsset->name}",
                    'debit' => $depreciationAmount,
                    'credit' => 0,
                ]);

                // Credit: Accumulated Depreciation
                $entry->lines()->create([
                    'account_id' => $accumulatedAcc,
                    'cost_center_id' => $fixedAsset->cost_center_id,
                    'description' => "مجمع إهلاك {$fixedAsset->name}",
                    'debit' => 0,
                    'credit' => $depreciationAmount,
                ]);
            }

            AssetDepreciation::create([
                'fixed_asset_id' => $fixedAsset->id,
                'date' => $validated['date'],
                'amount' => $depreciationAmount,
                'journal_entry_id' => $entry?->id,
                'notes' => $validated['notes'] ?? null,
            ]);

            $newTotalDepreciated = $fixedAsset->total_depreciated + $depreciationAmount;
            $newBookValue = max($fixedAsset->salvage_value, $fixedAsset->purchase_cost - $newTotalDepreciated);

            $fixedAsset->update([
                'total_depreciated' => $newTotalDepreciated,
                'current_book_value' => $newBookValue,
            ]);
        });

        return redirect()->route('fixed-assets.index')->with('success', 'تم احتساب الإهلاك وتوليد القيد المحاسبي بنجاح');
    }

    public function destroy(FixedAsset $fixedAsset)
    {
        $fixedAsset->depreciations()->delete();
        $fixedAsset->delete();
        return redirect()->route('fixed-assets.index')->with('success', 'تم حذف الأصل الثابت وسجل إهلاكاته بنجاح');
    }
}
