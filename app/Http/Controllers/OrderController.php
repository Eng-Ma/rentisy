<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Invoice;
use App\Models\StoreItem;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    /**
     * Display a listing of orders in Admin Panel.
     */
    public function index(Request $request)
    {
        $query = Order::with(['user', 'party', 'invoice', 'items.item']);

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('order_number', 'like', "%{$search}%")
                  ->orWhere('shipping_name', 'like', "%{$search}%")
                  ->orWhere('shipping_phone', 'like', "%{$search}%")
                  ->orWhereHas('items', function ($qi) use ($search) {
                      $qi->where('item_name', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('payment_method')) {
            $query->where('payment_method', $request->input('payment_method'));
        }

        if ($request->filled('date')) {
            $query->whereDate('created_at', $request->input('date'));
        }

        $orders = $query->latest()->paginate(15)->withQueryString();

        // Calculate KPI Metrics for Admin Dashboard Cards
        $totalOrders = Order::count();
        $pendingOrders = Order::where('status', 'pending')->count();
        $processingOrders = Order::where('status', 'processing')->count();
        $shippedOrders = Order::where('status', 'shipped')->count();
        $deliveredOrders = Order::where('status', 'delivered')->count();
        $cancelledOrders = Order::where('status', 'cancelled')->count();
        $totalRevenue = Order::where('status', '!=', 'cancelled')->sum('total_amount');

        return Inertia::render('Orders/Index', [
            'orders' => $orders,
            'filters' => $request->only(['search', 'status', 'payment_method', 'date']),
            'metrics' => [
                'totalOrders' => $totalOrders,
                'pendingOrders' => $pendingOrders,
                'processingOrders' => $processingOrders,
                'shippedOrders' => $shippedOrders,
                'deliveredOrders' => $deliveredOrders,
                'cancelledOrders' => $cancelledOrders,
                'totalRevenue' => round($totalRevenue, 2),
            ]
        ]);
    }

    /**
     * Display detailed order view.
     */
    public function show($id)
    {
        $order = Order::with(['user', 'party', 'invoice.lines.item', 'items.item'])
            ->findOrFail($id);

        return Inertia::render('Orders/Show', [
            'order' => $order,
        ]);
    }

    /**
     * Update order status and synchronize inventory / invoice.
     */
    public function updateStatus(Request $request, $id)
    {
        $validated = $request->validate([
            'status' => 'required|in:pending,processing,shipped,delivered,cancelled',
            'notes' => 'nullable|string',
        ]);

        $order = Order::with(['items', 'invoice'])->findOrFail($id);
        $oldStatus = $order->status;
        $newStatus = $validated['status'];

        DB::transaction(function () use ($order, $oldStatus, $newStatus, $validated) {
            $order->status = $newStatus;
            if (!empty($validated['notes'])) {
                $order->notes = ($order->notes ? $order->notes . " | " : "") . $validated['notes'];
            }

            // If changing to delivered and payment was cod, mark payment as paid
            if ($newStatus === 'delivered' && $order->payment_method === 'cod') {
                $order->payment_status = 'paid';
            }

            // If order was cancelled, restore warehouse inventory stock
            if ($newStatus === 'cancelled' && $oldStatus !== 'cancelled') {
                foreach ($order->items as $itemLine) {
                    if ($itemLine->item_id) {
                        $storeItem = StoreItem::where('item_id', $itemLine->item_id)->first();
                        if ($storeItem) {
                            $storeItem->increment('quantity', $itemLine->quantity);
                        }
                    }
                }
            }

            $order->save();
        });

        return back()->with('success', 'تم تحديث حالة الطلب بنجاح إلى: ' . $newStatus);
    }

    /**
     * Delete order.
     */
    public function destroy($id)
    {
        $order = Order::findOrFail($id);
        $order->delete();

        return redirect()->route('orders.index')->with('success', 'تم حذف الطلب بنجاح.');
    }
}
