<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StockTransfer extends Model
{
    protected $fillable = [
        'transfer_number',
        'type',
        'from_store_id',
        'to_store_id',
        'date',
        'notes',
        'status',
        'journal_entry_id',
    ];

    protected $casts = [
        'date' => 'date',
    ];

    public function fromStore()
    {
        return $this->belongsTo(Store::class, 'from_store_id');
    }

    public function toStore()
    {
        return $this->belongsTo(Store::class, 'to_store_id');
    }

    public function lines()
    {
        return $this->hasMany(StockTransferLine::class);
    }

    public function journalEntry()
    {
        return $this->belongsTo(JournalEntry::class, 'journal_entry_id');
    }
}
