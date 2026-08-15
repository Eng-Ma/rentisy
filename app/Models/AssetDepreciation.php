<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AssetDepreciation extends Model
{
    protected $fillable = [
        'fixed_asset_id',
        'date',
        'amount',
        'journal_entry_id',
        'notes',
    ];

    protected $casts = [
        'date' => 'date',
        'amount' => 'float',
    ];

    public function fixedAsset()
    {
        return $this->belongsTo(FixedAsset::class);
    }

    public function journalEntry()
    {
        return $this->belongsTo(JournalEntry::class);
    }
}
