<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DeliveryZone extends Model
{
    protected $fillable = [
        'name',
        'city',
        'delivery_fee',
        'estimated_time',
        'is_active',
        'is_approved',
        'suggested_by_user_id',
        'status',
        'admin_notes',
    ];

    protected $casts = [
        'delivery_fee' => 'float',
        'is_active' => 'boolean',
        'is_approved' => 'boolean',
    ];

    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    public function suggestedByUser()
    {
        return $this->belongsTo(User::class, 'suggested_by_user_id');
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true)->where('is_approved', true);
    }

    public function scopePendingSuggestions($query)
    {
        return $query->where('status', 'pending');
    }
}
