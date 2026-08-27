<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Quotation;
use App\Models\Party;
use App\Models\Store;
use App\Models\Item;
use App\Models\Invoice;
use App\Models\StoreItem;
use App\Models\JournalEntry;
use App\Models\Currency;
use App\Models\Account;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class QuotationApiController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->query('status');

        $query = Quotation::with(['party', 'store', 'lines.item', 'convertedInvoice'])
            ->orderBy('date', 'desc')
            ->orderBy('id', 'desc');

        if ($status) {
            $query->where('status', $status);
        }

        $quotations = $query->paginate($request->input('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $quotations->items(),
            'current_page' => $quotations->currentPage(),
            'last_page' => $quotations->lastPage(),
            'total' => $quotations->total(),
        ]);
    }

    public function show(Quotation $quotation)
    {
        return response()->json([
            'success' => true,
            'data' => $quotation->load(['party', 'store', 'lines.item', 'convertedInvoice']),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'quotation_number' => 'nullable|string|unique:quotations,quotation_number',
            'party_id' => 'required|exists:parties,id',
            'store_id' => 'nullable|exists:stores,id',
            'date' => 'required|date',
            'expiry_date' => 'nullable|date',
            'discount' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string',
            'lines' => 'required|array|min:1',
            'lines.*.item_id' => 'required|exists:items,id',
            'lines.*.quantity' => 'required|numeric|min:0.01',
            'lines.*.unit_price' => 'required|numeric|min:0',
        ]);

        if (empty($validated['quotation_number'])) {
            $lastQuote = Quotation::latest('id')->first();
            $nextNum = $lastQuote ? ((int)substr($lastQuote->quotation_number, 4) + 1) : 1;
            $validated['quotation_number'] = 'QTN-' . str_pad((string)$nextNum, 5, '0', STR_PAD_LEFT);
        }

        $quotation = DB::transaction(function () use ($validated) {
            $subtotal = 0;
            $processedLines = [];

            foreach ($validated['lines'] as $line) {
                $qty = (float)$line['quantity'];
                $price = (float)$line['unit_price'];
                $total = $qty * $price;
                $subtotal += $total;

                $processedLines[] = [
                    'item_id' => $line['item_id'],
                    'quantity' => $qty,
                    'unit_price' => $price,
                    'total_price' => $total,
                    'notes' => $line['notes'] ?? null,
                ];
            }

            $discount = (float)($validated['discount'] ?? 0);
            $totalAmount = max(0, $subtotal - $discount);

            $quotation = Quotation::create([
                'quotation_number' => $validated['quotation_number'],
                'party_id' => $validated['party_id'],
                'store_id' => $validated['store_id'] ?? null,
                'date' => $validated['date'],
                'expiry_date' => $validated['expiry_date'] ?? null,
                'status' => 'draft',
                'subtotal' => $subtotal,
                'discount' => $discount,
                'total_amount' => $totalAmount,
                'notes' => $validated['notes'] ?? null,
            ]);

            foreach ($processedLines as $pLine) {
                $quotation->lines()->create($pLine);
            }

            return $quotation;
        });

        return response()->json([
            'success' => true,
            'message' => 'تم إنشاء عرض السعر بنجاح',
            'data' => $quotation->load(['party', 'store', 'lines.item']),
        ], 201);
    }

    public function convertToInvoice(Quotation $quotation)
    {
        if ($quotation->status === 'converted') {
            return response()->json([
                'success' => false,
                'message' => 'تم تحويل عرض السعر هذا مسبقاً إلى فاتورة.',
            ], 422);
        }

        $invoice = DB::transaction(function () use ($quotation) {
            $storeId = $quotation->store_id ?? Store::first()?->id;
            $totalAmount = $quotation->total_amount;
            $totalCost = 0;

            $invoice = Invoice::create([
                'type' => 'sale',
                'date' => date('Y-m-d'),
                'party_id' => $quotation->party_id,
                'store_id' => $storeId,
                'total_amount' => $totalAmount,
                'notes' => "فاتورة محولة من عرض سعر رقم: {$quotation->quotation_number}",
            ]);

            foreach ($quotation->lines as $line) {
                $item = $line->item;
                $itemCost = (float)($item ? $item->purchase_price : 0);
                $totalCost += $line->quantity * $itemCost;

                $invoice->lines()->create([
                    'item_id' => $line->item_id,
                    'quantity' => $line->quantity,
                    'unit_price' => $line->unit_price,
                    'total_price' => $line->total_price,
                ]);

                if ($storeId) {
                    $storeItem = StoreItem::firstOrCreate(
                        ['store_id' => $storeId, 'item_id' => $line->item_id],
                        ['quantity' => 0]
                    );
                    $storeItem->quantity -= $line->quantity;
                    $storeItem->save();
                }
            }

            // Journal Entry
            $currency = Currency::where('is_default', true)->first() ?? Currency::first();
            $party = $quotation->party;
            $partyAccount = $party->account_id ?? Account::where('code', '1103')->first()?->id;
            $salesAccount = Account::where('code', '4101')->first()?->id;
            $cogsAccount = Account::where('code', '5101')->first()?->id;
            $inventoryAccount = Account::where('code', '1104')->first()?->id;

            if ($partyAccount && $currency) {
                $journalEntry = JournalEntry::create([
                    'date' => date('Y-m-d'),
                    'description' => "فاتورة مبيعات محولة من عرض سعر {$quotation->quotation_number}",
                    'reference' => 'INV-' . $invoice->id,
                    'currency_id' => $currency->id,
                    'exchange_rate' => 1.0,
                ]);

                $journalEntry->lines()->create(['account_id' => $partyAccount, 'debit' => $totalAmount, 'credit' => 0]);
                if ($salesAccount) $journalEntry->lines()->create(['account_id' => $salesAccount, 'debit' => 0, 'credit' => $totalAmount]);
                if ($cogsAccount && $inventoryAccount && $totalCost > 0) {
                    $journalEntry->lines()->create(['account_id' => $cogsAccount, 'debit' => $totalCost, 'credit' => 0]);
                    $journalEntry->lines()->create(['account_id' => $inventoryAccount, 'debit' => 0, 'credit' => $totalCost]);
                }

                $invoice->update(['journal_entry_id' => $journalEntry->id]);
            }

            $quotation->update([
                'status' => 'converted',
                'converted_invoice_id' => $invoice->id,
            ]);

            return $invoice;
        });

        return response()->json([
            'success' => true,
            'message' => 'تم تحويل عرض السعر إلى فاتورة مبيعات بنجاح',
            'data' => $invoice->load(['party', 'store', 'lines.item']),
        ]);
    }

    public function destroy(Quotation $quotation)
    {
        $quotation->lines()->delete();
        $quotation->delete();

        return response()->json([
            'success' => true,
            'message' => 'تم حذف عرض السعر بنجاح',
        ]);
    }
}
