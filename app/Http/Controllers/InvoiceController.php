<?php

namespace App\Http\Controllers;

use App\Models\Invoice;
use App\Models\Party;
use App\Models\Store;
use App\Models\Item;
use App\Models\StoreItem;
use App\Models\JournalEntry;
use App\Models\Currency;
use App\Models\Account;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\DB;

class InvoiceController extends Controller
{
    public function index(Request $request)
    {
        $query = Invoice::with(['party', 'store']);

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

        $invoices = $query->latest('date')->latest('id')->paginate(10)->withQueryString();

        return Inertia::render('Invoices/Index', [
            'invoices' => $invoices,
            'filters' => $request->only(['search', 'type', 'date'])
        ]);
    }

    public function create()
    {
        $parties = Party::all();
        $stores = Store::where('is_active', true)->get();
        $items = Item::where('is_active', true)->get();
        
        return Inertia::render('Invoices/Create', [
            'parties' => $parties,
            'stores' => $stores,
            'items' => $items,
        ]);
    }

    public function store(Request $request)
    {
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

                $itemCost = Item::find($line['item_id'])->purchase_price;
                $totalCost += $line['quantity'] * $itemCost;
            }

            // Create Invoice
            $invoice = Invoice::create([
                'type' => $validated['type'],
                'date' => $validated['date'],
                'party_id' => $validated['party_id'],
                'store_id' => $validated['store_id'],
                'total_amount' => $totalAmount,
                'notes' => $validated['notes'],
            ]);

            // Create Lines and Update Inventory
            foreach ($validated['lines'] as $line) {
                $invoice->lines()->create($line);

                // Update StoreItem
                $storeItem = StoreItem::firstOrCreate(
                    ['store_id' => $validated['store_id'], 'item_id' => $line['item_id']],
                    ['quantity' => 0]
                );

                if ($validated['type'] === 'purchase' || $validated['type'] === 'sale_return') {
                    $storeItem->quantity += $line['quantity']; // Add to stock
                } else {
                    $storeItem->quantity -= $line['quantity']; // Remove from stock
                }
                $storeItem->save();
            }

            // Automation: Create Journal Entry
            $party = Party::find($validated['party_id']);
            $currency = Currency::where('is_default', true)->first(); // Use default currency for MVP
            
            // Basic Accounts for MVP
            $partyAccount = $party->account_id ?? Account::where('code', in_array($validated['type'], ['sale', 'sale_return']) ? '1103' : '2101')->first()->id ?? null; 
            $salesAccount = Account::where('code', '4101')->first()->id ?? null;
            $cogsAccount = Account::where('code', '5101')->first()->id ?? null;
            $inventoryAccount = Account::where('code', '1104')->first()->id ?? null;
            
            if ($partyAccount && $currency) {
                $journalEntry = JournalEntry::create([
                    'date' => $validated['date'],
                    'description' => "فاتورة " . __($validated['type']) . " رقم " . $invoice->id,
                    'reference' => 'INV-' . $invoice->id,
                    'currency_id' => $currency->id,
                    'exchange_rate' => 1.0,
                ]);

                if ($validated['type'] === 'sale') {
                    // Debit Customer, Credit Sales
                    $journalEntry->lines()->create(['account_id' => $partyAccount, 'debit' => $totalAmount, 'credit' => 0]);
                    $journalEntry->lines()->create(['account_id' => $salesAccount, 'debit' => 0, 'credit' => $totalAmount]);
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
                    $journalEntry->lines()->create(['account_id' => $salesAccount, 'debit' => $totalAmount, 'credit' => 0]);
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

        return redirect()->route('invoices.show', $invoice->id)->with('success', 'تم حفظ الفاتورة بنجاح وتحديث المخازن والحسابات.');
    }

    public function show(Invoice $invoice)
    {
        $invoice->load(['party', 'store', 'lines.item', 'journalEntry']);
        
        return Inertia::render('Invoices/Show', [
            'invoice' => $invoice
        ]);
    }
}
