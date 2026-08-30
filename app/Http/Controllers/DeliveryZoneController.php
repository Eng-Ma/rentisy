<?php

namespace App\Http\Controllers;

use App\Models\DeliveryZone;
use Illuminate\Http\Request;
use Inertia\Inertia;

class DeliveryZoneController extends Controller
{
    /**
     * Display a listing of delivery zones and customer suggestions.
     */
    public function index(Request $request)
    {
        $zones = DeliveryZone::where('is_approved', true)
            ->orderBy('city')
            ->orderBy('delivery_fee')
            ->get();

        $suggestions = DeliveryZone::where('status', 'pending')
            ->with('suggestedByUser')
            ->latest()
            ->get();

        return Inertia::render('DeliveryZones/Index', [
            'zones' => $zones,
            'suggestions' => $suggestions,
        ]);
    }

    /**
     * Store a newly created delivery zone.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'city' => 'required|string|max:100',
            'delivery_fee' => 'required|numeric|min:0',
            'estimated_time' => 'nullable|string|max:100',
            'is_active' => 'boolean',
            'admin_notes' => 'nullable|string|max:1000',
        ]);

        $validated['is_approved'] = true;
        $validated['status'] = 'approved';

        DeliveryZone::create($validated);

        return redirect()->back()->with('success', 'تمت إضافة منطقة التوصيل بنجاح.');
    }

    /**
     * Update the specified delivery zone.
     */
    public function update(Request $request, DeliveryZone $deliveryZone)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'city' => 'required|string|max:100',
            'delivery_fee' => 'required|numeric|min:0',
            'estimated_time' => 'nullable|string|max:100',
            'is_active' => 'boolean',
            'admin_notes' => 'nullable|string|max:1000',
        ]);

        $deliveryZone->update($validated);

        return redirect()->back()->with('success', 'تم تحديث بيانات منطقة التوصيل بنجاح.');
    }

    /**
     * Remove the specified delivery zone.
     */
    public function destroy(DeliveryZone $deliveryZone)
    {
        $deliveryZone->delete();

        return redirect()->back()->with('success', 'تم حذف منطقة التوصيل بنجاح.');
    }

    /**
     * Approve a customer suggested zone.
     */
    public function approveSuggestion(Request $request, DeliveryZone $deliveryZone)
    {
        $validated = $request->validate([
            'delivery_fee' => 'required|numeric|min:0',
            'name' => 'nullable|string|max:255',
            'estimated_time' => 'nullable|string|max:100',
            'admin_notes' => 'nullable|string|max:1000',
        ]);

        $deliveryZone->update([
            'name' => $validated['name'] ?? $deliveryZone->name,
            'delivery_fee' => $validated['delivery_fee'],
            'estimated_time' => $validated['estimated_time'] ?? 'خلال 24-48 ساعة',
            'is_active' => true,
            'is_approved' => true,
            'status' => 'approved',
            'admin_notes' => $validated['admin_notes'] ?? 'تم اعتماد المنطقة المقترحة من قبل الإدارة.',
        ]);

        return redirect()->back()->with('success', "تم اعتماد منطقة التوصيل المقترحة ({$deliveryZone->name}) بنجاح وتفعيلها في المتجر.");
    }

    /**
     * Reject a customer suggested zone.
     */
    public function rejectSuggestion(Request $request, DeliveryZone $deliveryZone)
    {
        $validated = $request->validate([
            'admin_notes' => 'nullable|string|max:1000',
        ]);

        $deliveryZone->update([
            'is_active' => false,
            'status' => 'rejected',
            'admin_notes' => $validated['admin_notes'] ?? 'تم رفض الاقتراح لعدم توفر خط توصيل حالياً.',
        ]);

        return redirect()->back()->with('success', "تم رفض اقتراح المنطقة ({$deliveryZone->name}).");
    }
}
