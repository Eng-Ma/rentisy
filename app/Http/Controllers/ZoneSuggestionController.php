<?php

namespace App\Http\Controllers;

use App\Models\DeliveryZone;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ZoneSuggestionController extends Controller
{
    /**
     * Store customer suggested delivery zone (Limit: 2 per customer).
     */
    public function store(Request $request)
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'يرجى تسجيل الدخول أولاً لاقتراح منطقة توصيل جديدة.',
            ], 401);
        }

        // Count user suggestions
        $existingCount = DeliveryZone::where('suggested_by_user_id', $user->id)->count();

        if ($existingCount >= 2) {
            return response()->json([
                'status' => 'error',
                'message' => 'عذراً، لقد استنفدت الحد الأقصى المسموح به لاقتراح المناطق (منطقتين فقط لكل عميل). يمكنك التواصل مع الدعم الفني لمزيد من المساعدة.',
            ], 422);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'city' => 'required|string|max:100',
            'notes' => 'nullable|string|max:500',
        ]);

        $zone = DeliveryZone::create([
            'name' => $validated['name'],
            'city' => $validated['city'],
            'delivery_fee' => 0.00, // Admin sets this upon approval
            'estimated_time' => 'قيد المراجعة',
            'is_active' => false,
            'is_approved' => false,
            'suggested_by_user_id' => $user->id,
            'status' => 'pending',
            'admin_notes' => $validated['notes'] ? "ملاحظة العميل: " . $validated['notes'] : null,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => "تم استلام اقتراحك لإضافة منطقة ({$zone->name}) بنجاح! سيتم مراجعتها من قبل الإدارة وإضافتها فور اعتماد خط التوصيل.",
            'zone' => $zone,
            'remaining_suggestions' => 2 - ($existingCount + 1),
        ]);
    }
}
