<?php

namespace App\Http\Controllers;

use App\Models\TransferMethod;
use Illuminate\Http\Request;
use Inertia\Inertia;

class TransferMethodController extends Controller
{
    /**
     * Display a listing of transfer payment methods.
     */
    public function index(Request $request)
    {
        $methods = TransferMethod::orderBy('sort_order')
            ->orderBy('id')
            ->get();

        return Inertia::render('TransferMethods/Index', [
            'methods' => $methods,
        ]);
    }

    /**
     * Store a newly created transfer payment method.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'account_name' => 'nullable|string|max:255',
            'account_number' => 'nullable|string|max:100',
            'iban' => 'nullable|string|max:100',
            'phone' => 'nullable|string|max:50',
            'instructions' => 'nullable|string|max:2000',
            'logo_url' => 'nullable|string|max:500',
            'logo' => 'nullable|file|image|max:5120',
            'is_active' => 'boolean',
            'sort_order' => 'integer|min:0',
        ]);

        if ($request->hasFile('logo')) {
            $path = $request->file('logo')->store('payment_logos', 'public');
            $validated['logo_url'] = '/storage/' . $path;
        }

        unset($validated['logo']);

        TransferMethod::create($validated);

        return redirect()->back()->with('success', 'تمت إضافة طريقة التحويل البنكي/المحفظة بنجاح.');
    }

    /**
     * Update the specified transfer payment method.
     */
    public function update(Request $request, TransferMethod $transferMethod)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'account_name' => 'nullable|string|max:255',
            'account_number' => 'nullable|string|max:100',
            'iban' => 'nullable|string|max:100',
            'phone' => 'nullable|string|max:50',
            'instructions' => 'nullable|string|max:2000',
            'logo_url' => 'nullable|string|max:500',
            'logo' => 'nullable|file|image|max:5120',
            'is_active' => 'boolean',
            'sort_order' => 'integer|min:0',
        ]);

        if ($request->hasFile('logo')) {
            $path = $request->file('logo')->store('payment_logos', 'public');
            $validated['logo_url'] = '/storage/' . $path;
        }

        unset($validated['logo']);

        $transferMethod->update($validated);

        return redirect()->back()->with('success', 'تم تحديث بيانات طريقة التحويل بنجاح.');
    }

    /**
     * Remove the specified transfer payment method.
     */
    public function destroy(TransferMethod $transferMethod)
    {
        $transferMethod->delete();

        return redirect()->back()->with('success', 'تم حذف طريقة التحويل بنجاح.');
    }

    /**
     * Toggle active status.
     */
    public function toggle(TransferMethod $transferMethod)
    {
        $transferMethod->update([
            'is_active' => !$transferMethod->is_active,
        ]);

        return redirect()->back()->with('success', 'تم تحديث حالة تفعيل طريقة التحويل.');
    }
}
