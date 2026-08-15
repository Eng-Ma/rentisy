<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Check extends Model
{
    protected $fillable = [
        'check_number',
        'type',
        'bank_name',
        'branch',
        'drawer_name',
        'beneficiary_name',
        'issue_date',
        'due_date',
        'amount',
        'currency_id',
        'status',
        'party_id',
        'endorsed_party_id',
        'voucher_id',
        'journal_entry_id',
        'collection_date',
        'notes',
    ];

    protected $casts = [
        'issue_date' => 'date',
        'due_date' => 'date',
        'collection_date' => 'date',
        'amount' => 'float',
    ];

    public function currency()
    {
        return $this->belongsTo(Currency::class, 'currency_id');
    }

    public function party()
    {
        return $this->belongsTo(Party::class, 'party_id');
    }

    public function endorsedParty()
    {
        return $this->belongsTo(Party::class, 'endorsed_party_id');
    }

    public function voucher()
    {
        return $this->belongsTo(Voucher::class, 'voucher_id');
    }

    public function journalEntry()
    {
        return $this->belongsTo(JournalEntry::class, 'journal_entry_id');
    }
}
