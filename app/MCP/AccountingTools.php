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
use App\Models\Category;
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
    public function createCustomer(?string $name = null, ?string $phone = null, ?string $address = null, ?int $accountId = null): string
    {
        $customerName = $name ?: ('Customer ' . date('Ymd-His'));
        $party = Party::create([
            'type' => 'customer',
            'name' => $customerName,
            'phone' => $phone,
            'address' => $address,
            'account_id' => $accountId,
        ]);

        return "Customer created successfully with ID: {$party->id}\n" . $party->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_vendor', description: 'Create a new vendor party')]
    public function createVendor(?string $name = null, ?string $phone = null, ?string $address = null, ?int $accountId = null): string
    {
        $vendorName = $name ?: ('Vendor ' . date('Ymd-His'));
        $party = Party::create([
            'type' => 'vendor',
            'name' => $vendorName,
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
    public function createItem(?string $name = null, float $purchasePrice = 10.0, float $salesPrice = 15.0, string $unit = 'piece', ?int $categoryId = null, ?string $barcode = null, ?string $description = null): string
    {
        $itemName = $name ?: ('Product ' . rand(100, 999));
        $item = Item::create([
            'name' => $itemName,
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

    #[McpTool(name: 'create_store', description: 'Create a new store or warehouse')]
    public function createStore(?string $name = null, ?string $location = null, bool $isActive = true): string
    {
        $storeName = $name ?: ('Store ' . rand(100, 999));
        $store = Store::create([
            'name' => $storeName,
            'location' => $location,
            'is_active' => $isActive,
        ]);

        return "Store created successfully with ID: {$store->id}\n" . $store->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_categories', description: 'Get a list of item categories')]
    public function getCategories(): string
    {
        $categories = Category::all();
        if ($categories->isEmpty()) return "No categories found.";
        return "Found " . $categories->count() . " categories:\n" . $categories->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_category', description: 'Create a new item category')]
    public function createCategory(?string $name = null, ?string $description = null, ?int $parentId = null, bool $isActive = true): string
    {
        $categoryName = $name ?: ('Category ' . rand(10, 99));
        $category = Category::create([
            'name' => $categoryName,
            'description' => $description,
            'parent_id' => $parentId,
            'is_active' => $isActive,
        ]);

        return "Category created successfully with ID: {$category->id}\n" . $category->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_invoice', description: 'Create a new invoice (type: sale, purchase, sale_return, purchase_return). All parameters are optional with smart defaults.')]
    public function createInvoice(?string $type = 'sale', ?int $partyId = null, ?int $storeId = null, mixed $linesJson = null, ?string $date = null, ?string $notes = null): string
    {
        $type = in_array($type, ['sale', 'purchase', 'sale_return', 'purchase_return']) ? $type : 'sale';

        // 1. Resolve Party
        $party = $partyId ? Party::find($partyId) : null;
        if (!$party) {
            $expectedType = in_array($type, ['sale', 'sale_return']) ? 'customer' : 'vendor';
            $party = Party::where('type', $expectedType)->first() ?? Party::first();
        }
        if (!$party) {
            $party = Party::create([
                'type' => in_array($type, ['sale', 'sale_return']) ? 'customer' : 'vendor',
                'name' => 'Default ' . ucfirst(in_array($type, ['sale', 'sale_return']) ? 'Customer' : 'Vendor'),
                'phone' => '0500000000',
            ]);
        }

        // 2. Resolve Store
        $store = $storeId ? Store::find($storeId) : null;
        if (!$store) {
            $store = Store::where('is_active', true)->first() ?? Store::first();
        }
        if (!$store) {
            $store = Store::create([
                'name' => 'Main Store',
                'is_active' => true,
            ]);
        }

        // 3. Resolve Lines Data
        $linesData = [];
        if (!empty($linesJson)) {
            $linesData = is_array($linesJson) ? $linesJson : json_decode($linesJson, true);
        }

        if (empty($linesData) || !is_array($linesData)) {
            $item = Item::where('is_active', true)->first() ?? Item::first();
            if (!$item) {
                $item = Item::create([
                    'name' => 'Sample Product',
                    'purchase_price' => 50,
                    'sales_price' => 100,
                    'unit' => 'piece',
                    'is_active' => true,
                ]);
            }
            $linesData = [
                [
                    'item_id' => $item->id,
                    'quantity' => 1,
                    'unit_price' => (float)$item->sales_price,
                ]
            ];
        }

        $invoiceDate = $date ?? date('Y-m-d');
        $notes = $notes ?? 'Generated via MCP';

        try {
            $invoice = DB::transaction(function () use ($type, $party, $store, $linesData, $invoiceDate, $notes) {
                $totalAmount = 0;
                $totalCost = 0;
                $processedLines = [];

                foreach ($linesData as $line) {
                    $itemId = $line['item_id'] ?? null;
                    $quantity = (float)($line['quantity'] ?? 1);
                    $unitPrice = isset($line['unit_price']) ? (float)$line['unit_price'] : 0;

                    $item = $itemId ? Item::find($itemId) : null;
                    if (!$item) {
                        $item = Item::first();
                    }
                    if (!$item) {
                        throw new \Exception("No items available in inventory to create invoice line.");
                    }

                    if ($unitPrice <= 0) {
                        $unitPrice = (float)($type === 'purchase' ? $item->purchase_price : $item->sales_price);
                    }

                    $totalPrice = $quantity * $unitPrice;
                    $itemCost = (float)$item->purchase_price;
                    $totalCost += $quantity * $itemCost;
                    $totalAmount += $totalPrice;

                    $processedLines[] = [
                        'item_id' => $item->id,
                        'quantity' => $quantity,
                        'unit_price' => $unitPrice,
                        'total_price' => $totalPrice,
                    ];
                }

                $invoice = Invoice::create([
                    'type' => $type,
                    'date' => $invoiceDate,
                    'party_id' => $party->id,
                    'store_id' => $store->id,
                    'total_amount' => $totalAmount,
                    'notes' => $notes,
                ]);

                foreach ($processedLines as $pLine) {
                    $invoice->lines()->create($pLine);

                    $storeItem = StoreItem::firstOrCreate(
                        ['store_id' => $store->id, 'item_id' => $pLine['item_id']],
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
    public function createAccount(?string $code = null, ?string $name = null, string $type = 'asset', string $balanceType = 'debit', ?int $parentId = null, ?string $description = null): string
    {
        $code = $code ?: ((string)rand(1900, 1999));
        $name = $name ?: ('Account ' . $code);

        if (!in_array($type, ['asset', 'liability', 'equity', 'revenue', 'expense'])) {
            $type = 'asset';
        }
        if (!in_array($balanceType, ['debit', 'credit'])) {
            $balanceType = 'debit';
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
    public function createJournalEntry(?string $description = 'Manual Journal Entry', mixed $linesJson = null, ?string $reference = null, ?string $date = null, ?int $currencyId = null, float $exchangeRate = 1.0): string
    {
        $linesData = [];
        if (!empty($linesJson)) {
            $linesData = is_array($linesJson) ? $linesJson : json_decode($linesJson, true);
        }

        if (empty($linesData) || !is_array($linesData)) {
            $acc1 = Account::first();
            $acc2 = Account::skip(1)->first() ?? $acc1;
            if (!$acc1 || !$acc2) {
                return "Error: No accounts available to create journal entry.";
            }
            $linesData = [
                ['account_id' => $acc1->id, 'debit' => 100, 'credit' => 0, 'description' => 'Debit leg'],
                ['account_id' => $acc2->id, 'debit' => 0, 'credit' => 100, 'description' => 'Credit leg'],
            ];
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
