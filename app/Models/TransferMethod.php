<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TransferMethod extends Model
{
    protected $fillable = [
        'name',
        'account_name',
        'account_number',
        'iban',
        'phone',
        'logo_url',
        'instructions',
        'is_active',
        'sort_order',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];

    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true)->orderBy('sort_order')->orderBy('id');
    }
}
