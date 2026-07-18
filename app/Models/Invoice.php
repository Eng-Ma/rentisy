<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Invoice extends Model
{
    protected $fillable = [
        'type',
        'date',
        'party_id',
        'store_id',
        'total_amount',
        'notes',
        'journal_entry_id',
    ];

    public function party()
    {
        return $this->belongsTo(Party::class);
    }

    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    public function journalEntry()
    {
        return $this->belongsTo(JournalEntry::class);
    }

    public function lines()
    {
        return $this->hasMany(InvoiceLine::class);
    }
}
