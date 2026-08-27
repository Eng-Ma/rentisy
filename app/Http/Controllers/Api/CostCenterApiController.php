<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CostCenter;
use Illuminate\Http\Request;

class CostCenterApiController extends Controller
{
    public function index()
    {
        $costCenters = CostCenter::with('parent')
            ->withCount(['journalLines', 'vouchers', 'invoices'])
            ->orderBy('code')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $costCenters,
        ]);
    }

    public function show(CostCenter $costCenter)
    {
        return response()->json([
            'success' => true,
            'data' => $costCenter->load(['parent', 'children', 'journalLines.journalEntry', 'journalLines.account']),
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

        $costCenter = CostCenter::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'تم إنشاء مركز التكلفة بنجاح',
            'data' => $costCenter->load('parent'),
        ], 201);
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

        return response()->json([
            'success' => true,
            'message' => 'تم تحديث مركز التكلفة بنجاح',
            'data' => $costCenter->load('parent'),
        ]);
    }

    public function destroy(CostCenter $costCenter)
    {
        if ($costCenter->journalLines()->count() > 0 || $costCenter->vouchers()->count() > 0 || $costCenter->invoices()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'لا يمكن حذف مركز التكلفة لوجود حركات مالية مرتبطة به.',
            ], 422);
        }

        $costCenter->delete();

        return response()->json([
            'success' => true,
            'message' => 'تم حذف مركز التكلفة بنجاح',
        ]);
    }
}
