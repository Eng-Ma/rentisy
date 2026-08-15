<?php

namespace App\Http\Controllers\Settings;

use App\Http\Controllers\Controller;
use App\Models\McpToken;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Str;

class McpSettingsController extends Controller
{
    public function index(Request $request)
    {
        $tokens = McpToken::with('user:id,name,email')
            ->orderBy('created_at', 'desc')
            ->get();

        $mcpUrl = url('/mcp/sse');
        $oauthUrl = url('/oauth/authorize');

        return Inertia::render('settings/Mcp', [
            'tokens' => $tokens,
            'mcpUrl' => $mcpUrl,
            'oauthUrl' => $oauthUrl,
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:100',
        ]);

        $plainToken = 'mcp_' . Str::random(40);

        $mcpToken = McpToken::create([
            'user_id' => $request->user()->id,
            'name' => $request->input('name'),
            'token' => $plainToken,
            'is_active' => true,
        ]);

        return back()->with('success', "تم إنشاء مفتاح MCP بنجاح: {$plainToken}");
    }

    public function toggle(McpToken $token)
    {
        $token->update([
            'is_active' => !$token->is_active,
        ]);

        return back()->with('success', 'تم تحديث حالة مفتاح MCP');
    }

    public function destroy(McpToken $token)
    {
        $token->delete();
        return back()->with('success', 'تم حذف مفتاح MCP بنجاح');
    }
}
