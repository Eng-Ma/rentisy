<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class McpToken extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'token',
        'client_id',
        'last_used_at',
        'expires_at',
        'is_active',
    ];

    protected $casts = [
        'last_used_at' => 'datetime',
        'expires_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
