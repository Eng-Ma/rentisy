<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\Auth;

class AdminMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (!Auth::check()) {
            return redirect()->guest(route('admin.login'));
        }

        $user = Auth::user();

        if ($user->role !== 'admin') {
            if ($request->wantsJson()) {
                return response()->json([
                    'error' => 'Forbidden',
                    'message' => 'هذه الصفحة مخصصة لمدير النظام المحاسبي فقط.'
                ], 403);
            }

            return redirect()->route('customer.dashboard')->with('error', 'عذراً، هذه اللوحة مخصصة لإدارة النظام المحاسبي فقط ولا يملك حسابك صلاحية الدخول إليها.');
        }

        return $next($request);
    }
}
