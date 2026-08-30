<?php

namespace App\Http\Controllers;

use App\Models\LoyaltyTransaction;
use App\Models\Order;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\Auth;

class LoyaltyController extends Controller
{
    /**
     * Customer Loyalty & Cashback Wallet Dashboard.
     */
    public function index(Request $request)
    {
        $user = Auth::user();

        // Ensure referral code
        if (empty($user->referral_code)) {
            $user->referral_code = 'RENTISY-' . strtoupper(substr(md5($user->id . $user->email), 0, 6));
            $user->save();
        }

        $transactions = LoyaltyTransaction::where('user_id', $user->id)
            ->latest()
            ->take(20)
            ->get();

        // If no transactions yet, grant welcome bonus points
        if ($transactions->isEmpty() && $user->points_balance > 0) {
            LoyaltyTransaction::create([
                'user_id' => $user->id,
                'points' => $user->points_balance,
                'type' => 'welcome_bonus',
                'description' => 'هدية ترحيبية فورية عند التسجيل في متجر رنتيسي',
            ]);
            $transactions = LoyaltyTransaction::where('user_id', $user->id)->get();
        }

        // Tiers info:
        // Bronze: 0 - 200 pts (1% cashback)
        // Silver: 201 - 500 pts (2% cashback)
        // Gold: 501 - 1000 pts (3.5% cashback + free delivery)
        // Diamond: 1001+ pts (5% cashback + VIP priority support + exclusive discounts)
        $points = $user->points_balance ?? 0;
        $tier = 'bronze';
        $nextTierTarget = 200;
        $cashbackRate = '1%';

        if ($points >= 1000) {
            $tier = 'diamond';
            $nextTierTarget = 2000;
            $cashbackRate = '5%';
        } elseif ($points >= 500) {
            $tier = 'gold';
            $nextTierTarget = 1000;
            $cashbackRate = '3.5%';
        } elseif ($points >= 200) {
            $tier = 'silver';
            $nextTierTarget = 500;
            $cashbackRate = '2%';
        }

        $user->tier = $tier;
        $user->save();

        $cashValue = round($points / 10, 2); // 10 points = 1 ₪

        return Inertia::render('Customer/Rewards', [
            'points' => $points,
            'cashValue' => $cashValue,
            'tier' => $tier,
            'cashbackRate' => $cashbackRate,
            'nextTierTarget' => $nextTierTarget,
            'referralCode' => $user->referral_code,
            'referralUrl' => url('/register?ref=' . $user->referral_code),
            'transactions' => $transactions,
        ]);
    }
}
