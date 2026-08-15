<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class QuotationLine extends Model
{
    protected $fillable = [
        'quotation_id',
        'item_id',
        'quantity',
        'unit_price',
        'total_price',
        'notes',
    ];

    protected $casts = [
        'quantity' => 'float',
        'unit_price' => 'float',
        'total_price' => 'float',
    ];

    public function quotation()
    {
        return $this->belongsTo(Quotation::class);
    }

    public function item()
    {
        return $this->belongsTo(Item::class);
    }
}
