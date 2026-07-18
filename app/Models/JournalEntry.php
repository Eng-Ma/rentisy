<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class JournalEntry extends Model
{
    protected $fillable = [
        'date',
        'reference',
        'description',
        'currency_id',
        'exchange_rate',
    ];

    public function currency()
    {
        return $this->belongsTo(Currency::class);
    }

    public function lines()
    {
        return $this->hasMany(JournalEntryLine::class);
    }
}
