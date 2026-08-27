<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\McpToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'بيانات الاعتماد غير صحيحة، يرجى التأكد من البريد وكلمة المرور.',
            ], 401);
        }

        $token = 'app_token_' . Str::random(60);

        McpToken::create([
            'user_id' => $user->id,
            'name' => 'Mobile App Session - ' . ($request->header('User-Agent') ? substr($request->header('User-Agent'), 0, 40) : 'Flutter App'),
            'token' => $token,
            'client_id' => 'flutter_mobile_app',
            'is_active' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'تم تسجيل الدخول بنجاح',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
        ]);
    }

    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $token = 'app_token_' . Str::random(60);

        McpToken::create([
            'user_id' => $user->id,
            'name' => 'Mobile App Session',
            'token' => $token,
            'client_id' => 'flutter_mobile_app',
            'is_active' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'تم إنشاء الحساب بنجاح',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
        ], 201);
    }

    public function me(Request $request)
    {
        $user = auth()->user() ?? User::first();
        return response()->json([
            'success' => true,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
        ]);
    }

    public function logout(Request $request)
    {
        $tokenString = $request->bearerToken();
        if ($tokenString) {
            McpToken::where('token', $tokenString)->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'تم تسجيل الخروج بنجاح',
        ]);
    }
}
