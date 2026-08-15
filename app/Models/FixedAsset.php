<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FixedAsset extends Model
{
    protected $fillable = [
        'code',
        'name',
        'purchase_date',
        'purchase_cost',
        'salvage_value',
        'useful_life_years',
        'depreciation_rate',
        'depreciation_method',
        'asset_account_id',
        'depreciation_expense_account_id',
        'accumulated_depreciation_account_id',
        'cost_center_id',
        'total_depreciated',
        'current_book_value',
        'is_active',
        'notes',
    ];

    protected $casts = [
        'purchase_date' => 'date',
        'purchase_cost' => 'float',
        'salvage_value' => 'float',
        'useful_life_years' => 'float',
        'depreciation_rate' => 'float',
        'total_depreciated' => 'float',
        'current_book_value' => 'float',
        'is_active' => 'boolean',
    ];

    public function assetAccount()
    {
        return $this->belongsTo(Account::class, 'asset_account_id');
    }

    public function depreciationExpenseAccount()
    {
        return $this->belongsTo(Account::class, 'depreciation_expense_account_id');
    }

    public function accumulatedDepreciationAccount()
    {
        return $this->belongsTo(Account::class, 'accumulated_depreciation_account_id');
    }

    public function costCenter()
    {
        return $this->belongsTo(CostCenter::class, 'cost_center_id');
    }

    public function depreciations()
    {
        return $this->hasMany(AssetDepreciation::class);
    }
}
