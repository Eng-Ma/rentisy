<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Party extends Model
{
    protected $fillable = [
        'type',
        'name',
        'phone',
        'address',
        'account_id',
    ];

    public function account()
    {
        return $this->belongsTo(Account::class);
    }

    public function invoices()
    {
        return $this->hasMany(Invoice::class);
    }

    public function vouchers()
    {
        return $this->hasMany(Voucher::class);
    }

    public function checks()
    {
        return $this->hasMany(Check::class);
    }

    public function quotations()
    {
        return $this->hasMany(Quotation::class);
    }
}
