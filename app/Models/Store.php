<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Store extends Model
{
    protected $fillable = [
        'name',
        'location',
        'is_active',
    ];

    public function storeItems()
    {
        return $this->hasMany(StoreItem::class);
    }
}
