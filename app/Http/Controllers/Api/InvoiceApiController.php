<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Party;
use App\Models\Store;
use App\Models\Item;
use App\Models\StoreItem;
use App\Models\JournalEntry;
use App\Models\Currency;
use App\Models\Account;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InvoiceApiController extends Controller
{
    public function index(Request $request)
    {
        $query = Invoice::with(['party', 'store', 'lines.item']);

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('id', 'like', "%{$search}%")
                  ->orWhere('notes', 'like', "%{$search}%")
                  ->orWhereHas('party', function ($q2) use ($search) {
                      $q2->where('name', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('type')) {
            $query->where('type', $request->input('type'));
        }
        
        if ($request->filled('date')) {
            $query->whereDate('date', $request->input('date'));
        }

        $invoices = $query->latest('date')->latest('id')->paginate($request->input('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $invoices->items(),
            'current_page' => $invoices->currentPage(),
            'last_page' => $invoices->lastPage(),
            'total' => $invoices->total(),
        ]);
    }

    public function show(Invoice $invoice)
    {
        return response()->json([
            'success' => true,
            'data' => $invoice->load(['party', 'store', 'lines.item', 'journalEntry.lines.account']),
        ]);
    }

    public function store(Request $request)
    {
        // 1. Auto-resolve Store if missing
        if (!$request->filled('store_id') || !Store::where('id', $request->input('store_id'))->exists()) {
            $store = Store::where('is_active', true)->first() ?? Store::first();
            if (!$store) {
                $store = Store::create([
                    'name' => 'المستودع الرئيسي',
                    'is_active' => true,
                ]);
            }
            $request->merge(['store_id' => $store->id]);
        }

        // 2. Auto-resolve Party if missing or party_name provided
        $type = $request->input('type', 'sale');
        if (!$request->filled('party_id') || !Party::where('id', $request->input('party_id'))->exists()) {
            $partyName = $request->input('party_name');
            $party = null;
            if ($partyName) {
                $party = Party::where('name', 'like', "%{$partyName}%")->first();
                if (!$party) {
                    $party = Party::create([
                        'name' => trim($partyName),
                        'type' => in_array($type, ['sale', 'sale_return']) ? 'customer' : 'vendor',
                        'phone' => '0500000000',
                    ]);
                }
            }
            if (!$party) {
                $expectedType = in_array($type, ['sale', 'sale_return']) ? 'customer' : 'vendor';
                $party = Party::where('type', $expectedType)->first() ?? Party::first();
                if (!$party) {
                    $party = Party::create([
                        'name' => in_array($type, ['sale', 'sale_return']) ? 'عميل عام' : 'مورد عام',
                        'type' => $expectedType,
                        'phone' => '0500000000',
                    ]);
                }
            }
            $request->merge(['party_id' => $party->id]);
        }

        // 3. Auto-resolve Date
        if (!$request->filled('date')) {
            $request->merge(['date' => date('Y-m-d')]);
        }

        // 4. Auto-resolve Lines if empty or missing
        $lines = $request->input('lines');
        if (empty($lines) || !is_array($lines) || count($lines) === 0) {
            $amount = (float)($request->input('amount') ?? $request->input('total_amount') ?? 100);
            $item = Item::where('is_active', true)->first() ?? Item::first();
            if (!$item) {
                $item = Item::create([
                    'name' => 'صنف عام / خدمات',
                    'purchase_price' => $amount,
                    'sales_price' => $amount,
                    'unit' => 'piece',
                    'is_active' => true,
                ]);
            }
            $request->merge([
                'lines' => [
                    [
                        'item_id' => $item->id,
                        'quantity' => 1,
                        'unit_price' => $amount,
                    ]
                ]
            ]);
        }

        $validated = $request->validate([
            'type' => 'required|in:purchase,sale,purchase_return,sale_return',
            'date' => 'required|date',
            'party_id' => 'required|exists:parties,id',
            'store_id' => 'required|exists:stores,id',
            'notes' => 'nullable|string',
            'lines' => 'required|array|min:1',
            'lines.*.item_id' => 'required|exists:items,id',
            'lines.*.quantity' => 'required|numeric|min:0.01',
            'lines.*.unit_price' => 'required|numeric|min:0',
        ]);

        $invoice = DB::transaction(function () use ($validated) {
            $totalAmount = 0;
            $totalCost = 0;

            foreach ($validated['lines'] as &$line) {
                $line['total_price'] = $line['quantity'] * $line['unit_price'];
                $totalAmount += $line['total_price'];

                $itemCost = Item::find($line['item_id'])->purchase_price ?? 0;
                $totalCost += $line['quantity'] * $itemCost;
            }

            // Create Invoice
            $invoice = Invoice::create([
                'type' => $validated['type'],
                'date' => $validated['date'],
                'party_id' => $validated['party_id'],
                'store_id' => $validated['store_id'],
                'total_amount' => $totalAmount,
                'notes' => $validated['notes'] ?? null,
            ]);

            // Create Lines and Update Inventory
            foreach ($validated['lines'] as $line) {
                $invoice->lines()->create($line);

                $storeItem = StoreItem::firstOrCreate(
                    ['store_id' => $validated['store_id'], 'item_id' => $line['item_id']],
                    ['quantity' => 0]
                );

                if ($validated['type'] === 'purchase' || $validated['type'] === 'sale_return') {
                    $storeItem->quantity += $line['quantity'];
                } else {
                    $storeItem->quantity -= $line['quantity'];
                }
                $storeItem->save();
            }

            // Automatic Journal Entry posting
            $party = Party::find($validated['party_id']);
            $currency = Currency::where('is_default', true)->first() ?? Currency::first();
            
            $partyAccount = $party->account_id ?? Account::where('code', in_array($validated['type'], ['sale', 'sale_return']) ? '1103' : '2101')->first()?->id; 
            $salesAccount = Account::where('code', '4101')->first()?->id;
            $cogsAccount = Account::where('code', '5101')->first()?->id;
            $inventoryAccount = Account::where('code', '1104')->first()?->id;
            
            if ($partyAccount && $currency) {
                $typeArabic = match($validated['type']) {
                    'sale' => 'مبيعات',
                    'purchase' => 'مشتريات',
                    'sale_return' => 'مردودات مبيعات',
                    'purchase_return' => 'مردودات مشتريات',
                    default => 'فاتورة'
                };

                $journalEntry = JournalEntry::create([
                    'date' => $validated['date'],
                    'description' => "فاتورة {$typeArabic} رقم " . $invoice->id,
                    'reference' => 'INV-' . $invoice->id,
                    'currency_id' => $currency->id,
                    'exchange_rate' => 1.0,
                ]);

                if ($validated['type'] === 'sale') {
                    // Debit Customer, Credit Sales
                    $journalEntry->lines()->create(['account_id' => $partyAccount, 'debit' => $totalAmount, 'credit' => 0]);
                    if ($salesAccount) $journalEntry->lines()->create(['account_id' => $salesAccount, 'debit' => 0, 'credit' => $totalAmount]);
                    // Debit COGS, Credit Inventory
                    if ($cogsAccount && $inventoryAccount && $totalCost > 0) {
                        $journalEntry->lines()->create(['account_id' => $cogsAccount, 'debit' => $totalCost, 'credit' => 0]);
                        $journalEntry->lines()->create(['account_id' => $inventoryAccount, 'debit' => 0, 'credit' => $totalCost]);
                    }
                } elseif ($validated['type'] === 'purchase') {
                    // Debit Inventory, Credit Supplier
                    if ($inventoryAccount) {
                        $journalEntry->lines()->create(['account_id' => $inventoryAccount, 'debit' => $totalAmount, 'credit' => 0]);
                        $journalEntry->lines()->create(['account_id' => $partyAccount, 'debit' => 0, 'credit' => $totalAmount]);
                    }
                } elseif ($validated['type'] === 'sale_return') {
                    // Debit Sales, Credit Customer
                    if ($salesAccount) $journalEntry->lines()->create(['account_id' => $salesAccount, 'debit' => $totalAmount, 'credit' => 0]);
                    $journalEntry->lines()->create(['account_id' => $partyAccount, 'debit' => 0, 'credit' => $totalAmount]);
                    // Debit Inventory, Credit COGS
                    if ($cogsAccount && $inventoryAccount && $totalCost > 0) {
                        $journalEntry->lines()->create(['account_id' => $inventoryAccount, 'debit' => $totalCost, 'credit' => 0]);
                        $journalEntry->lines()->create(['account_id' => $cogsAccount, 'debit' => 0, 'credit' => $totalCost]);
                    }
                } elseif ($validated['type'] === 'purchase_return') {
                    // Debit Supplier, Credit Inventory
                    if ($inventoryAccount) {
                        $journalEntry->lines()->create(['account_id' => $partyAccount, 'debit' => $totalAmount, 'credit' => 0]);
                        $journalEntry->lines()->create(['account_id' => $inventoryAccount, 'debit' => 0, 'credit' => $totalAmount]);
                    }
                }

                $invoice->update(['journal_entry_id' => $journalEntry->id]);
            }

            return $invoice;
        });

        return response()->json([
            'success' => true,
            'message' => 'تم حفظ الفاتورة بنجاح وتحديث أرصدة المخازن والقيود المحاسبية',
            'data' => $invoice->load(['party', 'store', 'lines.item', 'journalEntry']),
        ], 201);
    }

    public function destroy(Invoice $invoice)
    {
        DB::transaction(function () use ($invoice) {
            foreach ($invoice->lines as $line) {
                \App\Models\StoreItem::where('store_id', $invoice->store_id)
                    ->where('item_id', $line->item_id)
                    ->decrement('quantity', in_array($invoice->type, ['purchase', 'sale_return']) ? $line->quantity : -$line->quantity);
            }

            if ($invoice->journal_entry_id) {
                $entry = JournalEntry::find($invoice->journal_entry_id);
                if ($entry) {
                    $entry->lines()->delete();
                    $entry->delete();
                }
            }

            $invoice->lines()->delete();
            $invoice->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'تم حذف الفاتورة وإلغاء تأثيرها المخزني والمحاسبي بنجاح',
        ]);
    }
}
