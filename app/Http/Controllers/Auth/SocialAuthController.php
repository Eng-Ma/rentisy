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
use Laravel\Socialite\Facades\Socialite;

class SocialAuthController extends Controller
{
    /**
     * Redirect to the real social authentication provider (Google / Facebook).
     */
    public function redirect(Request $request, string $provider)
    {
        if (!in_array($provider, ['google', 'facebook'])) {
            return redirect()->route('login')->with('error', 'مزود تسجيل الدخول غير مدعوم.');
        }

        // Detect if this is an account connection from customer profile
        if ($request->input('action') === 'connect' || Auth::check()) {
            session(['social_action' => 'connect']);
            session(['social_user_id' => Auth::id()]);
        } else {
            session()->forget(['social_action', 'social_user_id']);
        }

        // Store return URL in session if provided
        if ($request->filled('return_url')) {
            session(['social_return_url' => $request->input('return_url')]);
        }

        $clientId = config("services.{$provider}.client_id");
        $clientSecret = config("services.{$provider}.client_secret");

        if (empty($clientId) || empty($clientSecret)) {
            $providerName = $provider === 'google' ? 'Google' : 'Facebook';
            $envKey = strtoupper($provider);
            
            $targetUrl = Auth::check() ? route('customer.profile') : route('login');
            return redirect($targetUrl)->with('error', "يرجى ضبط مفاتيح {$providerName} OAuth ({$envKey}_CLIENT_ID و {$envKey}_CLIENT_SECRET) في ملف .env لإتمام الربط الحقيقي.");
        }

        try {
            $driver = Socialite::driver($provider);
            
            if ($provider === 'google') {
                $driver->scopes(['openid', 'profile', 'email']);
            } elseif ($provider === 'facebook') {
                $driver->scopes(['email', 'public_profile']);
            }

            return $driver->redirect();
        } catch (\Throwable $e) {
            $targetUrl = Auth::check() ? route('customer.profile') : route('login');
            return redirect($targetUrl)->with('error', "تعذر بدء الاتصال بمزود " . ucfirst($provider) . ": " . $e->getMessage());
        }
    }

    /**
     * Handle real OAuth callback from provider.
     */
    public function callback(Request $request, string $provider)
    {
        if (!in_array($provider, ['google', 'facebook'])) {
            return redirect()->route('login')->with('error', 'مزود تسجيل الدخول غير مدعوم.');
        }

        // Check for error responses from OAuth provider (e.g. user cancelled)
        if ($request->has('error') || $request->has('error_description')) {
            $errorDesc = $request->input('error_description') ?? $request->input('error');
            $targetUrl = Auth::check() ? route('customer.profile') : route('login');
            return redirect($targetUrl)->with('error', "تم إلغاء عملية المصادقة من مزود " . ucfirst($provider) . ": {$errorDesc}");
        }

        try {
            $socialUser = Socialite::driver($provider)->user();
        } catch (\Throwable $e) {
            $targetUrl = Auth::check() ? route('customer.profile') : route('login');
            return redirect($targetUrl)->with('error', 'تعذر جلب بيانات الحساب من ' . ucfirst($provider) . ': ' . $e->getMessage());
        }

        $socialId = $socialUser->getId();
        $socialName = $socialUser->getName() ?? $socialUser->getNickname() ?? ('مستخدم ' . ucfirst($provider));
        $socialEmail = $socialUser->getEmail();
        $socialAvatar = $socialUser->getAvatar();
        $providerField = $provider . '_id';

        $action = session()->pull('social_action');
        $sessionUserId = session()->pull('social_user_id');

        // CASE 1: Connect Social Account to Existing Authenticated User
        if ($action === 'connect' || Auth::check() || $sessionUserId) {
            $userId = Auth::id() ?? $sessionUserId;
            $user = User::find($userId);

            if (!$user) {
                return redirect()->route('login')->with('error', 'يرجى تسجيل الدخول للربط.');
            }

            // Check if another user is already linked to this social ID
            $existingLinkedUser = User::where($providerField, $socialId)
                ->where('id', '!=', $user->id)
                ->first();

            if ($existingLinkedUser) {
                return redirect()->route('customer.profile')->with('error', "حساب {$provider} هذا مربوط بالفعل بحساب مستخدم آخر ({$existingLinkedUser->email}).");
            }

            $user->{$providerField} = $socialId;
            if (empty($user->avatar) && !empty($socialAvatar)) {
                $user->avatar = $socialAvatar;
            }
            $user->save();

            // Re-login if needed
            if (!Auth::check()) {
                Auth::login($user, true);
            }

            return redirect()->route('customer.profile')->with('success', 'تم ربط حساب ' . ($provider === 'google' ? 'Google' : 'Facebook') . ' الحقيقي بنجاح! 🎉');
        }

        // CASE 2: Social Login or Registration
        $user = null;

        // 1. Check if user already exists with this social provider ID
        if (!empty($socialId)) {
            $user = User::where($providerField, $socialId)->first();
        }

        // 2. If not found, check by email
        if (!$user && !empty($socialEmail)) {
            $user = User::where('email', $socialEmail)->first();
            if ($user) {
                $user->{$providerField} = $socialId;
                if (empty($user->avatar) && !empty($socialAvatar)) {
                    $user->avatar = $socialAvatar;
                }
                $user->save();
            }
        }

        // 3. If still not found, register new Customer and create ERP Party
        if (!$user) {
            // Find or link Accounts Receivable (1103)
            $arAccount = Account::where('code', '1103')->orWhere('name', 'like', '%عملاء%')->first();

            $party = Party::create([
                'type' => 'customer',
                'name' => $socialName,
                'phone' => null,
                'account_id' => $arAccount?->id,
            ]);

            // Generate referral code for new customer
            $referralCode = 'REF-' . strtoupper(Str::random(6));

            $user = User::create([
                'name' => $socialName,
                'email' => $socialEmail ?? ($provider . '_' . Str::random(8) . '@store.local'),
                'password' => Hash::make(Str::random(32)),
                'role' => 'customer',
                $providerField => $socialId,
                'avatar' => $socialAvatar,
                'party_id' => $party->id,
                'points_balance' => 0,
                'tier' => 'Bronze',
                'referral_code' => $referralCode,
            ]);
        }

        Auth::login($user, true);

        $returnUrl = session()->pull('social_return_url');
        if ($returnUrl) {
            return redirect($returnUrl);
        }

        return redirect()->route('customer.dashboard')->with('success', 'تم تسجيل الدخول بنجاح عبر حساب ' . ($provider === 'google' ? 'Google' : 'Facebook') . '!');
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
