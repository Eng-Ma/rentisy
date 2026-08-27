<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StockTransfer;
use App\Models\Store;
use App\Models\Item;
use App\Models\StoreItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StockTransferApiController extends Controller
{
    public function index(Request $request)
    {
        $type = $request->query('type');

        $query = StockTransfer::with(['fromStore', 'toStore', 'lines.item'])
            ->orderBy('date', 'desc')
            ->orderBy('id', 'desc');

        if ($type) {
            $query->where('type', $type);
        }

        $transfers = $query->paginate($request->input('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $transfers->items(),
            'current_page' => $transfers->currentPage(),
            'last_page' => $transfers->lastPage(),
            'total' => $transfers->total(),
        ]);
    }

    public function show(StockTransfer $stockTransfer)
    {
        return response()->json([
            'success' => true,
            'data' => $stockTransfer->load(['fromStore', 'toStore', 'lines.item']),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'transfer_number' => 'nullable|string|unique:stock_transfers,transfer_number',
            'type' => 'required|in:transfer,stock_in,stock_out,adjustment',
            'from_store_id' => 'nullable|required_if:type,transfer,stock_out|exists:stores,id',
            'to_store_id' => 'nullable|required_if:type,transfer,stock_in|exists:stores,id',
            'date' => 'required|date',
            'notes' => 'nullable|string',
            'lines' => 'required|array|min:1',
            'lines.*.item_id' => 'required|exists:items,id',
            'lines.*.quantity' => 'required|numeric|min:0.01',
            'lines.*.unit_cost' => 'nullable|numeric|min:0',
        ]);

        if ($validated['type'] === 'transfer' && $validated['from_store_id'] === $validated['to_store_id']) {
            return response()->json([
                'success' => false,
                'message' => 'لا يمكن أن يكون المستودع المحول منه والمحول إليه نفس المستودع.',
            ], 422);
        }

        if (empty($validated['transfer_number'])) {
            $lastTransfer = StockTransfer::latest('id')->first();
            $nextNum = $lastTransfer ? ((int)substr($lastTransfer->transfer_number, 3) + 1) : 1;
            $validated['transfer_number'] = 'TR-' . str_pad((string)$nextNum, 5, '0', STR_PAD_LEFT);
        }

        $transfer = DB::transaction(function () use ($validated) {
            $transfer = StockTransfer::create([
                'transfer_number' => $validated['transfer_number'],
                'type' => $validated['type'],
                'from_store_id' => $validated['from_store_id'] ?? null,
                'to_store_id' => $validated['to_store_id'] ?? null,
                'date' => $validated['date'],
                'notes' => $validated['notes'] ?? null,
                'status' => 'completed',
            ]);

            foreach ($validated['lines'] as $line) {
                $transfer->lines()->create([
                    'item_id' => $line['item_id'],
                    'quantity' => (float)$line['quantity'],
                    'unit_cost' => (float)($line['unit_cost'] ?? 0),
                    'notes' => $line['notes'] ?? null,
                ]);

                $qty = (float)$line['quantity'];

                // Deduct from source store
                if (!empty($validated['from_store_id'])) {
                    $fromStoreItem = StoreItem::firstOrCreate(
                        ['store_id' => $validated['from_store_id'], 'item_id' => $line['item_id']],
                        ['quantity' => 0]
                    );
                    $fromStoreItem->quantity -= $qty;
                    $fromStoreItem->save();
                }

                // Add to destination store
                if (!empty($validated['to_store_id'])) {
                    $toStoreItem = StoreItem::firstOrCreate(
                        ['store_id' => $validated['to_store_id'], 'item_id' => $line['item_id']],
                        ['quantity' => 0]
                    );
                    $toStoreItem->quantity += $qty;
                    $toStoreItem->save();
                }
            }

            return $transfer;
        });

        return response()->json([
            'success' => true,
            'message' => 'تم حفظ حركة المخزون وتحديث الأرصدة بنجاح',
            'data' => $transfer->load(['fromStore', 'toStore', 'lines.item']),
        ], 201);
    }

    public function destroy(StockTransfer $stockTransfer)
    {
        DB::transaction(function () use ($stockTransfer) {
            foreach ($stockTransfer->lines as $line) {
                $qty = (float)$line->quantity;

                if ($stockTransfer->from_store_id) {
                    $fromStoreItem = StoreItem::where('store_id', $stockTransfer->from_store_id)
                        ->where('item_id', $line->item_id)->first();
                    if ($fromStoreItem) {
                        $fromStoreItem->quantity += $qty;
                        $fromStoreItem->save();
                    }
                }

                if ($stockTransfer->to_store_id) {
                    $toStoreItem = StoreItem::where('store_id', $stockTransfer->to_store_id)
                        ->where('item_id', $line->item_id)->first();
                    if ($toStoreItem) {
                        $toStoreItem->quantity -= $qty;
                        $toStoreItem->save();
                    }
                }
            }

            $stockTransfer->lines()->delete();
            $stockTransfer->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'تم إلغاء حركة المخزون واسترجاع الأرصدة بنجاح',
        ]);
    }
}
