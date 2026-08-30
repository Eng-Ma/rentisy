<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    protected $fillable = [
        'order_number',
        'user_id',
        'party_id',
        'invoice_id',
        'status',
        'subtotal',
        'discount_amount',
        'points_earned',
        'points_redeemed',
        'cashback_discount',
        'shipping_fee',
        'total_amount',
        'payment_method',
        'payment_status',
        'payment_receipt_url',
        'is_payment_verified',
        'delivery_type',
        'delivery_zone_id',
        'shipping_name',
        'shipping_phone',
        'shipping_address',
        'shipping_city',
        'notes',
    ];

    protected $casts = [
        'subtotal' => 'decimal:2',
        'discount_amount' => 'decimal:2',
        'cashback_discount' => 'decimal:2',
        'shipping_fee' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'is_payment_verified' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function party()
    {
        return $this->belongsTo(Party::class);
    }

    public function invoice()
    {
        return $this->belongsTo(Invoice::class);
    }

    public function deliveryZone()
    {
        return $this->belongsTo(DeliveryZone::class, 'delivery_zone_id');
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }
}
