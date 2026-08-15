<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StockTransferLine extends Model
{
    protected $fillable = [
        'stock_transfer_id',
        'item_id',
        'quantity',
        'unit_cost',
        'notes',
    ];

    protected $casts = [
        'quantity' => 'float',
        'unit_cost' => 'float',
    ];

    public function transfer()
    {
        return $this->belongsTo(StockTransfer::class, 'stock_transfer_id');
    }

    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id');
    }
}
