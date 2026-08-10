<?php

namespace App\MCP;

use Mcp\Capability\Attribute\McpTool;
use App\Models\Account;
use App\Models\Invoice;
use App\Models\Party;
use App\Models\Item;
use App\Models\Store;
use App\Models\StoreItem;
use App\Models\JournalEntry;
use App\Models\Currency;
use Illuminate\Support\Facades\DB;

class AccountingTools
{
    #[McpTool(name: 'get_accounts', description: 'Get a list of all financial accounts')]
    public function getAccounts(): string
    {
        $accounts = Account::all();
        if ($accounts->isEmpty()) return "No accounts found.";
        return "Found " . $accounts->count() . " accounts:\n" . $accounts->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_invoices', description: 'Get a list of invoices with optional type filter (sale, purchase, purchase_return, sale_return, bill)')]
    public function getInvoices(?string $type = null, int $limit = 20): string
    {
        $query = Invoice::with(['party', 'store', 'lines'])->orderBy('created_at', 'desc');

        if ($type) {
            if ($type === 'bill') {
                $query->whereIn('type', ['purchase', 'bill']);
            } else {
                $query->where('type', $type);
            }
        }

        $invoices = $query->take($limit)->get();
        if ($invoices->isEmpty()) return "No invoices found matching criteria.";
        return "Found " . $invoices->count() . " invoices:\n" . $invoices->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_bills', description: 'Get a list of purchase bills')]
    public function getBills(int $limit = 20): string
    {
        $bills = Invoice::whereIn('type', ['purchase', 'bill'])
            ->with(['party', 'store', 'lines'])
            ->orderBy('created_at', 'desc')
            ->take($limit)
            ->get();

        if ($bills->isEmpty()) return "No purchase bills found.";
        return "Found " . $bills->count() . " purchase bills:\n" . $bills->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_system_status', description: 'Check if the accounting system is online')]
    public function getSystemStatus(): string
    {
        return 'System is online and running Laravel ' . app()->version();
    }

    #[McpTool(name: 'get_parties', description: 'Get a list of customer and vendor parties')]
    public function getParties(?string $type = null, ?string $search = null, int $limit = 20): string
    {
        $query = Party::with('account');

        if ($type) {
            $query->where('type', $type);
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhere('address', 'like', "%{$search}%");
            });
        }

        $parties = $query->take($limit)->get();
        if ($parties->isEmpty()) return "No parties found matching criteria.";
        return "Found " . $parties->count() . " parties:\n" . $parties->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_customer', description: 'Create a new customer party')]
    public function createCustomer(string $name, ?string $phone = null, ?string $address = null, ?int $accountId = null): string
    {
        $party = Party::create([
            'type' => 'customer',
            'name' => $name,
            'phone' => $phone,
            'address' => $address,
            'account_id' => $accountId,
        ]);

        return "Customer created successfully with ID: {$party->id}\n" . $party->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_vendor', description: 'Create a new vendor party')]
    public function createVendor(string $name, ?string $phone = null, ?string $address = null, ?int $accountId = null): string
    {
        $party = Party::create([
            'type' => 'vendor',
            'name' => $name,
            'phone' => $phone,
            'address' => $address,
            'account_id' => $accountId,
        ]);

        return "Vendor created successfully with ID: {$party->id}\n" . $party->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_items', description: 'Get a list of items / products in catalog')]
    public function getItems(?string $search = null, int $limit = 20): string
    {
        $query = Item::with('category');

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('barcode', 'like', "%{$search}%");
            });
        }

        $items = $query->take($limit)->get();
        if ($items->isEmpty()) return "No items found.";
        return "Found " . $items->count() . " items:\n" . $items->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_item', description: 'Create a new product or inventory item')]
    public function createItem(string $name, float $purchasePrice, float $salesPrice, string $unit = 'piece', ?int $categoryId = null, ?string $barcode = null, ?string $description = null): string
    {
        $item = Item::create([
            'name' => $name,
            'purchase_price' => $purchasePrice,
            'sales_price' => $salesPrice,
            'unit' => $unit,
            'category_id' => $categoryId,
            'barcode' => $barcode,
            'description' => $description,
            'is_active' => true,
        ]);

        return "Item created successfully with ID: {$item->id}\n" . $item->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_stores', description: 'Get a list of active stores / warehouses')]
    public function getStores(): string
    {
        $stores = Store::where('is_active', true)->get();
        if ($stores->isEmpty()) return "No active stores found.";
        return "Found " . $stores->count() . " stores:\n" . $stores->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_invoice', description: 'Create a new invoice (type: sale, purchase, sale_return, purchase_return) with lines (JSON array e.g. [{"item_id": 1, "quantity": 2, "unit_price": 50}])')]
    public function createInvoice(string $type, int $partyId, int $storeId, string $linesJson, ?string $date = null, ?string $notes = null): string
    {
        if (!in_array($type, ['sale', 'purchase', 'sale_return', 'purchase_return'])) {
            return "Error: Invalid invoice type '{$type}'. Must be one of: sale, purchase, sale_return, purchase_return.";
        }

        $party = Party::find($partyId);
        if (!$party) {
            return "Error: Party with ID {$partyId} not found.";
        }

        $store = Store::find($storeId);
        if (!$store) {
            return "Error: Store with ID {$storeId} not found.";
        }

        $linesData = is_array($linesJson) ? $linesJson : json_decode($linesJson, true);
        if (empty($linesData) || !is_array($linesData)) {
            return "Error: Invalid linesJson format. Must be a valid JSON array of objects with item_id, quantity, unit_price.";
        }

        $invoiceDate = $date ?? date('Y-m-d');

        try {
            $invoice = DB::transaction(function () use ($type, $partyId, $storeId, $linesData, $invoiceDate, $notes, $party) {
                $totalAmount = 0;
                $totalCost = 0;
                $processedLines = [];

                foreach ($linesData as $line) {
                    $itemId = $line['item_id'] ?? null;
                    $quantity = (float)($line['quantity'] ?? 1);
                    $unitPrice = (float)($line['unit_price'] ?? 0);
                    $totalPrice = $quantity * $unitPrice;

                    $item = Item::find($itemId);
                    if (!$item) {
                        throw new \Exception("Item with ID {$itemId} not found.");
                    }

                    $itemCost = (float)$item->purchase_price;
                    $totalCost += $quantity * $itemCost;
                    $totalAmount += $totalPrice;

                    $processedLines[] = [
                        'item_id' => $itemId,
                        'quantity' => $quantity,
                        'unit_price' => $unitPrice,
                        'total_price' => $totalPrice,
                    ];
                }

                $invoice = Invoice::create([
                    'type' => $type,
                    'date' => $invoiceDate,
                    'party_id' => $partyId,
                    'store_id' => $storeId,
                    'total_amount' => $totalAmount,
                    'notes' => $notes,
                ]);

                foreach ($processedLines as $pLine) {
                    $invoice->lines()->create($pLine);

                    $storeItem = StoreItem::firstOrCreate(
                        ['store_id' => $storeId, 'item_id' => $pLine['item_id']],
                        ['quantity' => 0]
                    );

                    if ($type === 'purchase' || $type === 'sale_return') {
                        $storeItem->quantity += $pLine['quantity'];
                    } else {
                        $storeItem->quantity -= $pLine['quantity'];
                    }
                    $storeItem->save();
                }

                $currency = Currency::where('is_default', true)->first() ?? Currency::first();
                $partyAccount = $party->account_id ?? Account::where('code', in_array($type, ['sale', 'sale_return']) ? '1103' : '2101')->first()?->id;
                $salesAccount = Account::where('code', '4101')->first()?->id;
                $cogsAccount = Account::where('code', '5101')->first()?->id;
                $inventoryAccount = Account::where('code', '1104')->first()?->id;

                if ($partyAccount && $currency) {
                    $journalEntry = JournalEntry::create([
                        'date' => $invoiceDate,
                        'description' => "فاتورة " . $type . " رقم " . $invoice->id,
                        'reference' => 'INV-' . $invoice->id,
                        'currency_id' => $currency->id,
                        'exchange_rate' => 1.0,
                    ]);

                    if ($type === 'sale') {
                        $journalEntry->lines()->create(['account_id' => $partyAccount, 'debit' => $totalAmount, 'credit' => 0]);
                        if ($salesAccount) $journalEntry->lines()->create(['account_id' => $salesAccount, 'debit' => 0, 'credit' => $totalAmount]);
                        if ($cogsAccount && $inventoryAccount && $totalCost > 0) {
                            $journalEntry->lines()->create(['account_id' => $cogsAccount, 'debit' => $totalCost, 'credit' => 0]);
                            $journalEntry->lines()->create(['account_id' => $inventoryAccount, 'debit' => 0, 'credit' => $totalCost]);
                        }
                    } elseif ($type === 'purchase') {
                        if ($inventoryAccount) $journalEntry->lines()->create(['account_id' => $inventoryAccount, 'debit' => $totalAmount, 'credit' => 0]);
                        $journalEntry->lines()->create(['account_id' => $partyAccount, 'debit' => 0, 'credit' => $totalAmount]);
                    } elseif ($type === 'sale_return') {
                        if ($salesAccount) $journalEntry->lines()->create(['account_id' => $salesAccount, 'debit' => $totalAmount, 'credit' => 0]);
                        $journalEntry->lines()->create(['account_id' => $partyAccount, 'debit' => 0, 'credit' => $totalAmount]);
                        if ($cogsAccount && $inventoryAccount && $totalCost > 0) {
                            $journalEntry->lines()->create(['account_id' => $inventoryAccount, 'debit' => $totalCost, 'credit' => 0]);
                            $journalEntry->lines()->create(['account_id' => $cogsAccount, 'debit' => 0, 'credit' => $totalCost]);
                        }
                    } elseif ($type === 'purchase_return') {
                        $journalEntry->lines()->create(['account_id' => $partyAccount, 'debit' => $totalAmount, 'credit' => 0]);
                        if ($inventoryAccount) $journalEntry->lines()->create(['account_id' => $inventoryAccount, 'debit' => 0, 'credit' => $totalAmount]);
                    }

                    $invoice->update(['journal_entry_id' => $journalEntry->id]);
                }

                return $invoice->load(['party', 'store', 'lines.item', 'journalEntry']);
            });

            return "Invoice created successfully with ID {$invoice->id}:\n" . $invoice->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        } catch (\Throwable $e) {
            return "Error creating invoice: " . $e->getMessage();
        }
    }

    #[McpTool(name: 'create_account', description: 'Create a new account in the chart of accounts')]
    public function createAccount(string $code, string $name, string $type, string $balanceType, ?int $parentId = null, ?string $description = null): string
    {
        if (!in_array($type, ['asset', 'liability', 'equity', 'revenue', 'expense'])) {
            return "Error: Invalid account type '{$type}'. Must be one of: asset, liability, equity, revenue, expense.";
        }
        if (!in_array($balanceType, ['debit', 'credit'])) {
            return "Error: Invalid balanceType '{$balanceType}'. Must be debit or credit.";
        }
        if (Account::where('code', $code)->exists()) {
            return "Error: Account code '{$code}' already exists.";
        }

        $account = Account::create([
            'code' => $code,
            'name' => $name,
            'type' => $type,
            'balance_type' => $balanceType,
            'parent_id' => $parentId,
            'description' => $description,
            'is_active' => true,
        ]);

        return "Account created successfully with ID: {$account->id}\n" . $account->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_journal_entry', description: 'Create a manual balanced journal entry')]
    public function createJournalEntry(string $description, string $linesJson, ?string $reference = null, ?string $date = null, ?int $currencyId = null, float $exchangeRate = 1.0): string
    {
        $linesData = is_array($linesJson) ? $linesJson : json_decode($linesJson, true);
        if (empty($linesData) || !is_array($linesData) || count($linesData) < 2) {
            return "Error: linesJson must be a JSON array of at least 2 line objects: [{\"account_id\": 1, \"debit\": 100, \"credit\": 0}]";
        }

        $totalDebit = 0;
        $totalCredit = 0;

        foreach ($linesData as $line) {
            $totalDebit += (float)($line['debit'] ?? 0);
            $totalCredit += (float)($line['credit'] ?? 0);
        }

        if (round($totalDebit, 6) !== round($totalCredit, 6)) {
            return "Error: Unbalanced journal entry. Total Debit ({$totalDebit}) does not equal Total Credit ({$totalCredit}).";
        }

        if ($totalDebit == 0) {
            return "Error: Journal entry total cannot be zero.";
        }

        $entryDate = $date ?? date('Y-m-d');
        $currency = $currencyId ? Currency::find($currencyId) : (Currency::where('is_default', true)->first() ?? Currency::first());

        if (!$currency) {
            return "Error: No valid currency found in system.";
        }

        try {
            $entry = DB::transaction(function () use ($entryDate, $reference, $description, $currency, $exchangeRate, $linesData) {
                $entry = JournalEntry::create([
                    'date' => $entryDate,
                    'reference' => $reference,
                    'description' => $description,
                    'currency_id' => $currency->id,
                    'exchange_rate' => $exchangeRate,
                ]);

                foreach ($linesData as $line) {
                    $entry->lines()->create([
                        'account_id' => $line['account_id'],
                        'description' => $line['description'] ?? null,
                        'debit' => (float)($line['debit'] ?? 0),
                        'credit' => (float)($line['credit'] ?? 0),
                    ]);
                }

                return $entry->load(['currency', 'lines.account']);
            });

            return "Journal entry created successfully with ID {$entry->id}:\n" . $entry->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        } catch (\Throwable $e) {
            return "Error creating journal entry: " . $e->getMessage();
        }
    }
}
