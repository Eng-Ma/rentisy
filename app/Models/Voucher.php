<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Voucher extends Model
{
    protected $fillable = [
        'voucher_number',
        'type',
        'payment_method',
        'date',
        'account_id',
        'party_id',
        'target_account_id',
        'cost_center_id',
        'currency_id',
        'exchange_rate',
        'amount',
        'check_number',
        'check_date',
        'bank_name',
        'notes',
        'journal_entry_id',
    ];

    protected $casts = [
        'date' => 'date',
        'check_date' => 'date',
        'amount' => 'float',
        'exchange_rate' => 'float',
    ];

    public function account()
    {
        return $this->belongsTo(Account::class, 'account_id');
    }

    public function party()
    {
        return $this->belongsTo(Party::class, 'party_id');
    }

    public function targetAccount()
    {
        return $this->belongsTo(Account::class, 'target_account_id');
    }

    public function costCenter()
    {
        return $this->belongsTo(CostCenter::class, 'cost_center_id');
    }

    public function currency()
    {
        return $this->belongsTo(Currency::class, 'currency_id');
    }

    public function journalEntry()
    {
        return $this->belongsTo(JournalEntry::class, 'journal_entry_id');
    }

    public function checks()
    {
        return $this->hasMany(Check::class);
    }
}
