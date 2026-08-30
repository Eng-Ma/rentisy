<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Item extends Model
{
    protected $fillable = [
        'category_id',
        'barcode',
        'name',
        'image',
        'description',
        'unit',
        'purchase_price',
        'sales_price',
        'discount_price',
        'is_active',
        'is_featured',
        'is_deal',
        'rating',
        'reviews_count',
        'tags',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'is_featured' => 'boolean',
        'is_deal' => 'boolean',
        'purchase_price' => 'decimal:2',
        'sales_price' => 'decimal:2',
        'discount_price' => 'decimal:2',
        'rating' => 'decimal:1',
        'reviews_count' => 'integer',
    ];

    public function getEffectivePriceAttribute()
    {
        return ($this->discount_price !== null && $this->discount_price > 0 && $this->discount_price < $this->sales_price)
            ? (float)$this->discount_price
            : (float)$this->sales_price;
    }

    public function getTotalStockAttribute()
    {
        return (float)$this->storeItems()->sum('quantity');
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function storeItems()
    {
        return $this->hasMany(StoreItem::class);
    }
}
