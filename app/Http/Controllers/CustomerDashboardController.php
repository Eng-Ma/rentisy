<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\WishlistItem;
use App\Models\CartItem;
use App\Models\Party;
use App\Models\Invoice;
use App\Models\Voucher;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class CustomerDashboardController extends Controller
{
    protected function getCustomerContext()
    {
        $userId = Auth::id();
        $cartCount = CartItem::where('user_id', $userId)->sum('quantity');
        $wishlistIds = WishlistItem::where('user_id', $userId)->pluck('item_id')->toArray();

        return [
            'cartCount' => (int)$cartCount,
            'wishlistIds' => $wishlistIds,
        ];
    }

    public function index(Request $request)
    {
        $user = Auth::user();

        $totalOrders = Order::where('user_id', $user->id)->count();
        $activeOrders = Order::where('user_id', $user->id)->whereIn('status', ['pending', 'processing', 'shipped'])->count();
        $totalSpent = Order::where('user_id', $user->id)->where('status', '!=', 'cancelled')->sum('total_amount');
        $wishlistCount = WishlistItem::where('user_id', $user->id)->count();

        $recentOrders = Order::where('user_id', $user->id)
            ->with(['items.item', 'invoice', 'transferMethod'])
            ->latest()
            ->take(5)
            ->get();

        return Inertia::render('Customer/Dashboard', [
            'stats' => [
                'totalOrders' => $totalOrders,
                'activeOrders' => $activeOrders,
                'totalSpent' => round($totalSpent, 2),
                'wishlistCount' => $wishlistCount,
            ],
            'recentOrders' => $recentOrders,
            'customer' => $user,
            'storeContext' => $this->getCustomerContext(),
        ]);
    }

    public function orders(Request $request)
    {
        $user = Auth::user();
        $query = Order::where('user_id', $user->id)->with(['items.item', 'invoice', 'transferMethod']);

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('order_number', 'like', "%{$search}%")
                  ->orWhereHas('items', function ($qi) use ($search) {
                      $qi->where('item_name', 'like', "%{$search}%");
                  });
            });
        }

        $orders = $query->latest()->paginate(10)->withQueryString();

        return Inertia::render('Customer/Orders', [
            'orders' => $orders,
            'filters' => $request->only(['status', 'search']),
            'customer' => $user,
            'storeContext' => $this->getCustomerContext(),
        ]);
    }

    public function orderShow(Request $request, $id)
    {
        $user = Auth::user();
        $order = Order::where('user_id', $user->id)
            ->with(['items.item', 'invoice.lines.item', 'party', 'transferMethod'])
            ->findOrFail($id);

        return Inertia::render('Customer/OrderShow', [
            'order' => $order,
            'customer' => $user,
            'storeContext' => $this->getCustomerContext(),
        ]);
    }

    public function profile(Request $request)
    {
        $user = Auth::user();

        return Inertia::render('Customer/Profile', [
            'customer' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'address' => $user->address,
                'city' => $user->city,
                'google_id' => $user->google_id,
                'facebook_id' => $user->facebook_id,
                'avatar' => $user->avatar,
                'role' => $user->role,
                'created_at' => $user->created_at->format('Y-m-d'),
            ],
            'socialConnections' => [
                'google' => !empty($user->google_id),
                'facebook' => !empty($user->facebook_id),
            ],
            'storeContext' => $this->getCustomerContext(),
        ]);
    }

    public function updateProfile(Request $request)
    {
        $user = Auth::user();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:50',
            'address' => 'nullable|string|max:500',
            'city' => 'nullable|string|max:100',
        ]);

        $user->update($validated);

        if ($user->party_id) {
            $party = Party::find($user->party_id);
            if ($party) {
                $party->update([
                    'name' => $validated['name'],
                    'phone' => $validated['phone'],
                    'address' => ($validated['city'] ? $validated['city'] . ' - ' : '') . $validated['address'],
                ]);
            }
        }

        return back()->with('success', 'تم حفظ بيانات الملف الشخصي بنجاح.');
    }

    public function updatePassword(Request $request)
    {
        $user = Auth::user();

        $validated = $request->validate([
            'current_password' => 'required|current_password',
            'password' => ['required', 'confirmed', Password::defaults()],
        ]);

        $user->update([
            'password' => Hash::make($validated['password']),
        ]);

        return back()->with('success', 'تم تغيير كلمة المرور بنجاح.');
    }

    public function statement(Request $request)
    {
        $user = Auth::user();
        $party = $user->party_id ? Party::with('account')->find($user->party_id) : null;

        $invoices = [];
        $vouchers = [];
        $totalDebit = 0;
        $totalCredit = 0;

        if ($party) {
            // Sales Invoices
            $invoices = Invoice::where('party_id', $party->id)
                ->with('lines.item')
                ->latest('date')
                ->get();

            // Vouchers (Receipts)
            $vouchers = Voucher::where('party_id', $party->id)
                ->latest('date')
                ->get();

            // Calculate totals
            foreach ($invoices as $inv) {
                $invTotal = $inv->lines->sum(fn($l) => $l->quantity * $l->unit_price);
                if ($inv->type === 'sale') {
                    $totalDebit += $invTotal;
                } elseif ($inv->type === 'sale_return') {
                    $totalCredit += $invTotal;
                }
            }

            foreach ($vouchers as $v) {
                if ($v->type === 'receipt') {
                    $totalCredit += $v->amount;
                } elseif ($v->type === 'payment') {
                    $totalDebit += $v->amount;
                }
            }
        }

        $balance = $totalDebit - $totalCredit;

        return Inertia::render('Customer/Statement', [
            'party' => $party,
            'invoices' => $invoices,
            'vouchers' => $vouchers,
            'summary' => [
                'totalDebit' => round($totalDebit, 2),
                'totalCredit' => round($totalCredit, 2),
                'balance' => round($balance, 2),
            ],
            'customer' => $user,
            'storeContext' => $this->getCustomerContext(),
        ]);
    }
}
