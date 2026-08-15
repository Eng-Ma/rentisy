<?php

namespace App\Http\Controllers;

use App\Models\CostCenter;
use Illuminate\Http\Request;
use Inertia\Inertia;

class CostCenterController extends Controller
{
    public function index()
    {
        $costCenters = CostCenter::with('parent')
            ->withCount(['journalLines', 'vouchers', 'invoices'])
            ->orderBy('code')
            ->get();

        return Inertia::render('CostCenters/Index', [
            'costCenters' => $costCenters,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'code' => 'required|string|unique:cost_centers,code',
            'name' => 'required|string|max:255',
            'parent_id' => 'nullable|exists:cost_centers,id',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        CostCenter::create($validated);

        return redirect()->route('cost-centers.index')->with('success', 'تم إنشاء مركز التكلفة بنجاح');
    }

    public function update(Request $request, CostCenter $costCenter)
    {
        $validated = $request->validate([
            'code' => 'required|string|unique:cost_centers,code,' . $costCenter->id,
            'name' => 'required|string|max:255',
            'parent_id' => 'nullable|exists:cost_centers,id',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $costCenter->update($validated);

        return redirect()->route('cost-centers.index')->with('success', 'تم تحديث مركز التكلفة بنجاح');
    }

    public function destroy(CostCenter $costCenter)
    {
        if ($costCenter->journalLines()->count() > 0 || $costCenter->vouchers()->count() > 0 || $costCenter->invoices()->count() > 0) {
            return back()->with('error', 'لا يمكن حذف مركز التكلفة لوجود حركات مالية مرتبطة به.');
        }

        $costCenter->delete();

        return redirect()->route('cost-centers.index')->with('success', 'تم حذف مركز التكلفة بنجاح');
    }
}
