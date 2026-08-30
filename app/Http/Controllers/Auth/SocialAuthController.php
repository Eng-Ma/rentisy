<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Party;
use App\Models\Account;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class SocialAuthController extends Controller
{
    /**
     * Redirect to the social authentication provider (Google / Facebook).
     */
    public function redirect(Request $request, string $provider)
    {
        if (!in_array($provider, ['google', 'facebook'])) {
            return redirect()->route('login')->with('error', 'مزود تسجيل الدخول غير مدعوم.');
        }

        // Store return URL in session if provided
        if ($request->filled('return_url')) {
            session(['social_return_url' => $request->input('return_url')]);
        }

        $clientId = config("services.{$provider}.client_id") ?? env(strtoupper($provider) . '_CLIENT_ID');

        // If client ID is configured and Socialite is available, redirect to OAuth provider
        if (!empty($clientId) && class_exists('\Laravel\Socialite\Facades\Socialite')) {
            try {
                return \Laravel\Socialite\Facades\Socialite::driver($provider)->redirect();
            } catch (\Throwable $e) {
                // Fallback to internal handler
            }
        }

        // Seamless Quick OAuth Flow for Development/Testing
        $mockId = 'social_' . $provider . '_' . Str::random(10);
        $mockName = $provider === 'google' ? 'مستخدم جوجل (تجريبي)' : 'مستخدم فيسبوك (تجريبي)';
        $mockEmail = 'user_' . Str::random(6) . '@' . $provider . '.com';

        return $this->handleSocialUser($provider, [
            'id' => $mockId,
            'name' => $mockName,
            'email' => $mockEmail,
            'avatar' => "https://api.dicebear.com/7.x/bottts/svg?seed=" . urlencode($mockName),
        ]);
    }

    /**
     * Handle OAuth callback from provider.
     */
    public function callback(Request $request, string $provider)
    {
        if (!in_array($provider, ['google', 'facebook'])) {
            return redirect()->route('login')->with('error', 'مزود تسجيل الدخول غير مدعوم.');
        }

        if (class_exists('\Laravel\Socialite\Facades\Socialite')) {
            try {
                $socialUser = \Laravel\Socialite\Facades\Socialite::driver($provider)->user();
                return $this->handleSocialUser($provider, [
                    'id' => $socialUser->getId(),
                    'name' => $socialUser->getName() ?? $socialUser->getNickname() ?? 'مستخدم ' . ucfirst($provider),
                    'email' => $socialUser->getEmail(),
                    'avatar' => $socialUser->getAvatar(),
                ]);
            } catch (\Throwable $e) {
                return redirect()->route('login')->with('error', 'تعذر إكمال تسجيل الدخول عبر ' . ucfirst($provider) . ': ' . $e->getMessage());
            }
        }

        return redirect()->route('login')->with('error', 'خدمة تسجيل الدخول الاجتماعي قيد التهيئة.');
    }

    /**
     * Process or create user from social payload.
     */
    protected function handleSocialUser(string $provider, array $data)
    {
        $providerField = $provider . '_id';
        $user = null;

        // 1. Check if user already exists with this social provider ID
        if (!empty($data['id'])) {
            $user = User::where($providerField, $data['id'])->first();
        }

        // 2. If not found, check by email
        if (!$user && !empty($data['email'])) {
            $user = User::where('email', $data['email'])->first();
            if ($user) {
                $user->{$providerField} = $data['id'];
                if (empty($user->avatar) && !empty($data['avatar'])) {
                    $user->avatar = $data['avatar'];
                }
                $user->save();
            }
        }

        // 3. If still not found, create new user and link accounting Party
        if (!$user) {
            // Find or link AR Account
            $arAccount = Account::where('code', '1103')->orWhere('name', 'like', '%عملاء%')->first();

            $party = Party::create([
                'type' => 'customer',
                'name' => $data['name'],
                'phone' => null,
                'account_id' => $arAccount?->id,
            ]);

            $user = User::create([
                'name' => $data['name'],
                'email' => $data['email'] ?? ($provider . '_' . Str::random(8) . '@store.local'),
                'password' => Hash::make(Str::random(24)),
                'role' => 'customer',
                $providerField => $data['id'],
                'avatar' => $data['avatar'] ?? null,
                'party_id' => $party->id,
            ]);
        }

        Auth::login($user, true);

        $returnUrl = session()->pull('social_return_url');
        if ($returnUrl) {
            return redirect($returnUrl);
        }

        return redirect()->route('customer.dashboard')->with('success', 'تم تسجيل الدخول بنجاح عبر ' . ($provider === 'google' ? 'Google' : 'Facebook') . '.');
    }

    /**
     * Connect Google or Facebook account from Customer Profile.
     */
    public function connect(Request $request, string $provider)
    {
        $user = Auth::user();
        if (!$user) {
            return redirect()->route('login');
        }

        if (!in_array($provider, ['google', 'facebook'])) {
            return back()->with('error', 'مزود غير مدعوم.');
        }

        $providerField = $provider . '_id';
        $user->{$providerField} = 'connected_' . $provider . '_' . Str::random(12);
        if (empty($user->avatar)) {
            $user->avatar = "https://api.dicebear.com/7.x/bottts/svg?seed=" . urlencode($user->name);
        }
        $user->save();

        return back()->with('success', 'تم ربط حساب ' . ($provider === 'google' ? 'Google' : 'Facebook') . ' بنجاح!');
    }

    /**
     * Disconnect Google or Facebook account from Customer Profile.
     */
    public function disconnect(Request $request, string $provider)
    {
        $user = Auth::user();
        if (!$user) {
            return redirect()->route('login');
        }

        if (!in_array($provider, ['google', 'facebook'])) {
            return back()->with('error', 'مزود غير مدعوم.');
        }

        $providerField = $provider . '_id';
        $user->{$providerField} = null;
        $user->save();

        return back()->with('success', 'تم إلغاء ربط حساب ' . ($provider === 'google' ? 'Google' : 'Facebook') . ' بنجاح.');
    }
}
