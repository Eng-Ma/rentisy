<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Quotation extends Model
{
    protected $fillable = [
        'quotation_number',
        'party_id',
        'store_id',
        'date',
        'expiry_date',
        'status',
        'subtotal',
        'discount',
        'tax_amount',
        'total_amount',
        'notes',
        'converted_invoice_id',
    ];

    protected $casts = [
        'date' => 'date',
        'expiry_date' => 'date',
        'subtotal' => 'float',
        'discount' => 'float',
        'tax_amount' => 'float',
        'total_amount' => 'float',
    ];

    public function party()
    {
        return $this->belongsTo(Party::class);
    }

    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    public function lines()
    {
        return $this->hasMany(QuotationLine::class);
    }

    public function convertedInvoice()
    {
        return $this->belongsTo(Invoice::class, 'converted_invoice_id');
    }
}
