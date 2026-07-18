<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StoreItem extends Model
{
    protected $fillable = [
        'store_id',
        'item_id',
        'quantity',
    ];

    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    public function item()
    {
        return $this->belongsTo(Item::class);
    }
}
