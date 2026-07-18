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
}
