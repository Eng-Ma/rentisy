<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Item extends Model
{
    protected $fillable = [
        'category_id',
        'barcode',
        'name',
        'description',
        'unit',
        'purchase_price',
        'sales_price',
        'is_active',
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function storeItems()
    {
        return $this->hasMany(StoreItem::class);
    }
}
