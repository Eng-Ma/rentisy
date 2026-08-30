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
use App\Models\CostCenter;
use App\Models\Voucher;
use App\Models\Check;
use App\Models\StockTransfer;
use App\Models\StockTransferLine;
use App\Models\Quotation;
use App\Models\QuotationLine;
use App\Models\FixedAsset;
use App\Models\AssetDepreciation;
use App\Models\JournalEntryLine;
use App\Models\Order;
use App\Models\OrderItem;
use Illuminate\Support\Facades\DB;

class AccountingTools
{
    // --- QUERY TOOLS ---

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

    #[McpTool(name: 'get_stores', description: 'Get a list of active stores / warehouses')]
    public function getStores(): string
    {
        $stores = Store::where('is_active', true)->get();
        if ($stores->isEmpty()) return "No active stores found.";
        return "Found " . $stores->count() . " stores:\n" . $stores->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_categories', description: 'Get a list of item categories')]
    public function getCategories(): string
    {
        $categories = Category::all();
        if ($categories->isEmpty()) return "No categories found.";
        return "Found " . $categories->count() . " categories:\n" . $categories->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    // --- CREATE TOOLS ---

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
    public function createInvoice(?string $type = 'sale', ?int $partyId = null, ?int $storeId = null, ?string $linesJson = null, ?string $date = null, ?string $notes = null): string
    {
        $type = in_array($type, ['sale', 'purchase', 'sale_return', 'purchase_return']) ? $type : 'sale';

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
    public function createJournalEntry(?string $description = 'Manual Journal Entry', ?string $linesJson = null, ?string $reference = null, ?string $date = null, ?int $currencyId = null, float $exchangeRate = 1.0): string
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

    // --- UPDATE TOOLS ---

    #[McpTool(name: 'update_party', description: 'Update an existing customer or vendor party by ID')]
    public function updateParty(int $id, ?string $name = null, ?string $phone = null, ?string $address = null, ?string $type = null, ?int $accountId = null): string
    {
        $party = Party::find($id);
        if (!$party) {
            return "Error: Party with ID {$id} not found.";
        }

        $data = array_filter([
            'name' => $name,
            'phone' => $phone,
            'address' => $address,
            'type' => $type,
            'account_id' => $accountId,
        ], fn($v) => $v !== null);

        $party->update($data);

        return "Party #{$id} updated successfully:\n" . $party->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'update_item', description: 'Update an existing product/item by ID')]
    public function updateItem(int $id, ?string $name = null, ?float $purchasePrice = null, ?float $salesPrice = null, ?string $unit = null, ?int $categoryId = null, ?string $barcode = null, ?string $description = null): string
    {
        $item = Item::find($id);
        if (!$item) {
            return "Error: Item with ID {$id} not found.";
        }

        $data = array_filter([
            'name' => $name,
            'purchase_price' => $purchasePrice,
            'sales_price' => $salesPrice,
            'unit' => $unit,
            'category_id' => $categoryId,
            'barcode' => $barcode,
            'description' => $description,
        ], fn($v) => $v !== null);

        $item->update($data);

        return "Item #{$id} updated successfully:\n" . $item->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'update_store', description: 'Update an existing store/warehouse by ID')]
    public function updateStore(int $id, ?string $name = null, ?string $location = null, ?bool $isActive = null): string
    {
        $store = Store::find($id);
        if (!$store) {
            return "Error: Store with ID {$id} not found.";
        }

        $data = array_filter([
            'name' => $name,
            'location' => $location,
            'is_active' => $isActive,
        ], fn($v) => $v !== null);

        $store->update($data);

        return "Store #{$id} updated successfully:\n" . $store->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'update_category', description: 'Update an existing item category by ID')]
    public function updateCategory(int $id, ?string $name = null, ?string $description = null, ?int $parentId = null, ?bool $isActive = null): string
    {
        $category = Category::find($id);
        if (!$category) {
            return "Error: Category with ID {$id} not found.";
        }

        $data = array_filter([
            'name' => $name,
            'description' => $description,
            'parent_id' => $parentId,
            'is_active' => $isActive,
        ], fn($v) => $v !== null);

        $category->update($data);

        return "Category #{$id} updated successfully:\n" . $category->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'update_account', description: 'Update an existing financial account by ID')]
    public function updateAccount(int $id, ?string $code = null, ?string $name = null, ?string $type = null, ?string $balanceType = null, ?int $parentId = null, ?string $description = null): string
    {
        $account = Account::find($id);
        if (!$account) {
            return "Error: Account with ID {$id} not found.";
        }

        $data = array_filter([
            'code' => $code,
            'name' => $name,
            'type' => $type,
            'balance_type' => $balanceType,
            'parent_id' => $parentId,
            'description' => $description,
        ], fn($v) => $v !== null);

        $account->update($data);

        return "Account #{$id} updated successfully:\n" . $account->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    // --- DELETE TOOLS ---

    #[McpTool(name: 'delete_invoice', description: 'Delete an invoice by ID and automatically revert inventory and associated journal entry')]
    public function deleteInvoice(?int $id = null): string
    {
        $invoice = $id ? Invoice::find($id) : Invoice::latest()->first();
        if (!$invoice) {
            return "Error: Invoice not found.";
        }

        $invoiceId = $invoice->id;

        try {
            DB::transaction(function () use ($invoice) {
                foreach ($invoice->lines as $line) {
                    $storeItem = StoreItem::where('store_id', $invoice->store_id)
                        ->where('item_id', $line->item_id)
                        ->first();
                    if ($storeItem) {
                        if (in_array($invoice->type, ['purchase', 'sale_return'])) {
                            $storeItem->quantity -= $line->quantity;
                        } else {
                            $storeItem->quantity += $line->quantity;
                        }
                        $storeItem->save();
                    }
                }

                if ($invoice->journal_entry_id) {
                    $journalEntry = JournalEntry::find($invoice->journal_entry_id);
                    if ($journalEntry) {
                        $journalEntry->lines()->delete();
                        $journalEntry->delete();
                    }
                }

                $invoice->lines()->delete();
                $invoice->delete();
            });

            return "Invoice #{$invoiceId} and its associated stock updates & journal entry deleted successfully.";
        } catch (\Throwable $e) {
            return "Error deleting invoice #{$invoiceId}: " . $e->getMessage();
        }
    }

    #[McpTool(name: 'delete_party', description: 'Delete a customer or vendor party by ID')]
    public function deleteParty(?int $id = null): string
    {
        $party = $id ? Party::find($id) : Party::latest()->first();
        if (!$party) {
            return "Error: Party not found.";
        }

        $partyId = $party->id;
        $partyName = $party->name;

        if ($party->invoices()->count() > 0) {
            return "Error: Cannot delete party '{$partyName}' (#{$partyId}) because it has existing invoices linked to it.";
        }

        try {
            $party->delete();
            return "Party '{$partyName}' (#{$partyId}) deleted successfully.";
        } catch (\Throwable $e) {
            return "Error deleting party #{$partyId}: " . $e->getMessage();
        }
    }

    #[McpTool(name: 'delete_item', description: 'Delete an inventory item by ID')]
    public function deleteItem(?int $id = null): string
    {
        $item = $id ? Item::find($id) : Item::latest()->first();
        if (!$item) {
            return "Error: Item not found.";
        }

        $itemId = $item->id;
        $itemName = $item->name;

        try {
            DB::transaction(function () use ($item) {
                StoreItem::where('item_id', $item->id)->delete();
                $item->delete();
            });
            return "Item '{$itemName}' (#{$itemId}) deleted successfully.";
        } catch (\Throwable $e) {
            return "Error deleting item #{$itemId}: " . $e->getMessage();
        }
    }

    #[McpTool(name: 'delete_store', description: 'Delete a store/warehouse by ID')]
    public function deleteStore(?int $id = null): string
    {
        $store = $id ? Store::find($id) : Store::latest()->first();
        if (!$store) {
            return "Error: Store not found.";
        }

        $storeId = $store->id;
        $storeName = $store->name;

        if (Invoice::where('store_id', $storeId)->count() > 0) {
            return "Error: Cannot delete store '{$storeName}' (#{$storeId}) because it has existing invoices linked to it.";
        }

        try {
            DB::transaction(function () use ($store) {
                StoreItem::where('store_id', $store->id)->delete();
                $store->delete();
            });
            return "Store '{$storeName}' (#{$storeId}) deleted successfully.";
        } catch (\Throwable $e) {
            return "Error deleting store #{$storeId}: " . $e->getMessage();
        }
    }

    #[McpTool(name: 'delete_category', description: 'Delete a category by ID')]
    public function deleteCategory(?int $id = null): string
    {
        $category = $id ? Category::find($id) : Category::latest()->first();
        if (!$category) {
            return "Error: Category not found.";
        }

        $categoryId = $category->id;
        $categoryName = $category->name;

        try {
            Item::where('category_id', $categoryId)->update(['category_id' => null]);
            $category->delete();
            return "Category '{$categoryName}' (#{$categoryId}) deleted successfully.";
        } catch (\Throwable $e) {
            return "Error deleting category #{$categoryId}: " . $e->getMessage();
        }
    }

    #[McpTool(name: 'delete_account', description: 'Delete a financial account by ID')]
    public function deleteAccount(?int $id = null): string
    {
        $account = $id ? Account::find($id) : Account::latest()->first();
        if (!$account) {
            return "Error: Account not found.";
        }

        $accountId = $account->id;
        $accountName = $account->name;

        try {
            $account->delete();
            return "Account '{$accountName}' (#{$accountId}) deleted successfully.";
        } catch (\Throwable $e) {
            return "Error deleting account #{$accountId}: " . $e->getMessage();
        }
    }

    #[McpTool(name: 'delete_journal_entry', description: 'Delete a manual journal entry by ID')]
    public function deleteJournalEntry(?int $id = null): string
    {
        $entry = $id ? JournalEntry::find($id) : JournalEntry::latest()->first();
        if (!$entry) {
            return "Error: Journal entry not found.";
        }

        $entryId = $entry->id;

        try {
            DB::transaction(function () use ($entry) {
                $entry->lines()->delete();
                $entry->delete();
            });
            return "Journal entry #{$entryId} deleted successfully.";
        } catch (\Throwable $e) {
            return "Error deleting journal entry #{$entryId}: " . $e->getMessage();
        }
    }

    // ==========================================
    // --- AL-ASEEL GOLDEN: VOUCHERS (السندات) ---
    // ==========================================

    #[McpTool(name: 'get_vouchers', description: 'Get a list of receipt and payment vouchers (type: receipt, payment)')]
    public function getVouchers(?string $type = null, int $limit = 20): string
    {
        $query = Voucher::with(['account', 'party', 'targetAccount', 'costCenter', 'currency'])
            ->orderBy('date', 'desc');

        if ($type) {
            $query->where('type', $type);
        }

        $vouchers = $query->take($limit)->get();
        if ($vouchers->isEmpty()) return "No vouchers found.";
        return "Found " . $vouchers->count() . " vouchers:\n" . $vouchers->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_voucher', description: 'Get full details of a single voucher by ID including party, accounts, cost center, and journal entry')]
    public function getVoucher(int $id): string
    {
        $voucher = Voucher::with(['account', 'party', 'targetAccount', 'costCenter', 'currency', 'journalEntry.lines.account'])->find($id);
        if (!$voucher) return "Error: Voucher with ID {$id} not found.";
        return "Voucher #{$id} details:\n" . $voucher->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_voucher', description: 'Create a new Receipt or Payment voucher with automatic double-entry journal generation (type: receipt [سند قبض], payment [سند صرف])')]
    public function createVoucher(string $type, float $amount, string $paymentMethod = 'cash', ?int $accountId = null, ?int $partyId = null, ?int $targetAccountId = null, ?int $costCenterId = null, ?string $checkNumber = null, ?string $bankName = null, ?string $date = null, ?string $notes = null): string
    {
        if (!in_array($type, ['receipt', 'payment'])) {
            return "Error: Invalid voucher type. Must be 'receipt' or 'payment'.";
        }

        $party = $partyId ? Party::find($partyId) : null;
        $account = $accountId ? Account::find($accountId) : (Account::where('code', $paymentMethod === 'cash' ? '1101' : '1102')->first() ?? Account::first());
        $currency = Currency::where('is_default', true)->first() ?? Currency::first();

        if (!$account) {
            return "Error: No valid cash or bank account found.";
        }

        $prefix = $type === 'receipt' ? 'RV-' : 'PV-';
        $lastVoucher = Voucher::where('type', $type)->latest('id')->first();
        $nextNum = $lastVoucher ? ((int)substr($lastVoucher->voucher_number, 3) + 1) : 1;
        $voucherNumber = $prefix . str_pad((string)$nextNum, 5, '0', STR_PAD_LEFT);

        $voucherDate = $date ?? date('Y-m-d');
        $counterpartAccountId = $targetAccountId;
        if (!$counterpartAccountId && $party) {
            $counterpartAccountId = $party->account_id ?? Account::where('code', $type === 'receipt' ? '1103' : '2101')->first()?->id;
        }

        try {
            $voucher = DB::transaction(function () use ($type, $amount, $paymentMethod, $account, $party, $counterpartAccountId, $costCenterId, $currency, $voucherNumber, $voucherDate, $checkNumber, $bankName, $notes) {
                $typeLabel = $type === 'receipt' ? 'سند قبض' : 'سند صرف';

                $journalEntry = JournalEntry::create([
                    'date' => $voucherDate,
                    'reference' => $voucherNumber,
                    'description' => "{$typeLabel} رقم {$voucherNumber} - " . ($notes ?? ''),
                    'currency_id' => $currency->id,
                    'exchange_rate' => 1.0,
                ]);

                if ($type === 'receipt') {
                    $journalEntry->lines()->create([
                        'account_id' => $account->id,
                        'cost_center_id' => $costCenterId,
                        'description' => "قبض نقدي/بنكي - {$voucherNumber}",
                        'debit' => $amount,
                        'credit' => 0,
                    ]);
                    $journalEntry->lines()->create([
                        'account_id' => $counterpartAccountId ?? $account->id,
                        'cost_center_id' => $costCenterId,
                        'description' => "تسديد/إيراد - {$voucherNumber}",
                        'debit' => 0,
                        'credit' => $amount,
                    ]);
                } else {
                    $journalEntry->lines()->create([
                        'account_id' => $counterpartAccountId ?? $account->id,
                        'cost_center_id' => $costCenterId,
                        'description' => "دفع/مصروف - {$voucherNumber}",
                        'debit' => $amount,
                        'credit' => 0,
                    ]);
                    $journalEntry->lines()->create([
                        'account_id' => $account->id,
                        'cost_center_id' => $costCenterId,
                        'description' => "صرف نقدي/بنكي - {$voucherNumber}",
                        'debit' => 0,
                        'credit' => $amount,
                    ]);
                }

                $voucher = Voucher::create([
                    'voucher_number' => $voucherNumber,
                    'type' => $type,
                    'payment_method' => $paymentMethod,
                    'date' => $voucherDate,
                    'account_id' => $account->id,
                    'party_id' => $party?->id,
                    'target_account_id' => $counterpartAccountId,
                    'cost_center_id' => $costCenterId,
                    'currency_id' => $currency->id,
                    'exchange_rate' => 1.0,
                    'amount' => $amount,
                    'check_number' => $checkNumber,
                    'bank_name' => $bankName,
                    'notes' => $notes,
                    'journal_entry_id' => $journalEntry->id,
                ]);

                if ($paymentMethod === 'check' && !empty($checkNumber)) {
                    Check::create([
                        'check_number' => $checkNumber,
                        'type' => $type === 'receipt' ? 'received' : 'issued',
                        'bank_name' => $bankName ?? 'البنك',
                        'due_date' => $voucherDate,
                        'issue_date' => $voucherDate,
                        'amount' => $amount,
                        'currency_id' => $currency->id,
                        'status' => 'under_collection',
                        'party_id' => $party?->id,
                        'voucher_id' => $voucher->id,
                        'journal_entry_id' => $journalEntry->id,
                        'notes' => $notes,
                    ]);
                }

                return $voucher->load(['account', 'party', 'targetAccount', 'costCenter', 'journalEntry']);
            });

            return "Voucher created successfully with ID {$voucher->id}:\n" . $voucher->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        } catch (\Throwable $e) {
            return "Error creating voucher: " . $e->getMessage();
        }
    }

    #[McpTool(name: 'create_receipt_voucher', description: 'Quick tool to create a Receipt Voucher (سند قبض) to receive money with automatic balanced journal entry')]
    public function createReceiptVoucher(float $amount, ?int $partyId = null, string $paymentMethod = 'cash', ?int $accountId = null, ?int $costCenterId = null, ?string $checkNumber = null, ?string $bankName = null, ?string $date = null, ?string $notes = null): string
    {
        return $this->createVoucher('receipt', $amount, $paymentMethod, $accountId, $partyId, null, $costCenterId, $checkNumber, $bankName, $date, $notes);
    }

    #[McpTool(name: 'create_payment_voucher', description: 'Quick tool to create a Payment Voucher (سند صرف) to pay money to a vendor or expense with automatic balanced journal entry')]
    public function createPaymentVoucher(float $amount, ?int $partyId = null, ?int $targetAccountId = null, string $paymentMethod = 'cash', ?int $accountId = null, ?int $costCenterId = null, ?string $date = null, ?string $notes = null): string
    {
        return $this->createVoucher('payment', $amount, $paymentMethod, $accountId, $partyId, $targetAccountId, $costCenterId, null, null, $date, $notes);
    }

    #[McpTool(name: 'update_voucher', description: 'Update an existing voucher (سند قبض أو صرف) by ID and automatically synchronize its double-entry journal entry')]
    public function updateVoucher(
        int $id,
        ?float $amount = null,
        ?string $date = null,
        ?string $paymentMethod = null,
        ?int $accountId = null,
        ?int $partyId = null,
        ?int $targetAccountId = null,
        ?int $costCenterId = null,
        ?string $checkNumber = null,
        ?string $bankName = null,
        ?string $notes = null
    ): string {
        $voucher = Voucher::find($id);
        if (!$voucher) return "Error: Voucher with ID {$id} not found.";

        try {
            DB::transaction(function () use ($voucher, $amount, $date, $paymentMethod, $accountId, $partyId, $targetAccountId, $costCenterId, $checkNumber, $bankName, $notes) {
                if ($amount !== null) $voucher->amount = $amount;
                if ($date !== null) $voucher->date = $date;
                if ($paymentMethod !== null) $voucher->payment_method = $paymentMethod;
                if ($accountId !== null) $voucher->account_id = $accountId;
                if ($partyId !== null) $voucher->party_id = $partyId ?: null;
                if ($targetAccountId !== null) $voucher->target_account_id = $targetAccountId;
                if ($costCenterId !== null) $voucher->cost_center_id = $costCenterId;
                if ($checkNumber !== null) $voucher->check_number = $checkNumber;
                if ($bankName !== null) $voucher->bank_name = $bankName;
                if ($notes !== null) $voucher->notes = $notes;

                $voucher->save();

                // Synchronize Journal Entry
                if ($voucher->journal_entry_id) {
                    $journalEntry = JournalEntry::find($voucher->journal_entry_id);
                    if ($journalEntry) {
                        $typeLabel = $voucher->type === 'receipt' ? 'سند قبض' : 'سند صرف';
                        $journalEntry->update([
                            'date' => $voucher->date,
                            'description' => "{$typeLabel} رقم {$voucher->voucher_number} - " . ($voucher->notes ?? ''),
                        ]);

                        $journalEntry->lines()->delete();

                        $accId = $voucher->account_id;
                        $counterpartId = $voucher->target_account_id;
                        if (!$counterpartId && $voucher->party_id) {
                            $party = Party::find($voucher->party_id);
                            $counterpartId = $party?->account_id ?? Account::where('code', $voucher->type === 'receipt' ? '1103' : '2101')->first()?->id;
                        }
                        if (!$counterpartId) $counterpartId = $accId;

                        $amt = (float)$voucher->amount;
                        $ccId = $voucher->cost_center_id;

                        if ($voucher->type === 'receipt') {
                            $journalEntry->lines()->create([
                                'account_id' => $accId,
                                'cost_center_id' => $ccId,
                                'description' => "قبض نقدي/بنكي - {$voucher->voucher_number}",
                                'debit' => $amt,
                                'credit' => 0,
                            ]);
                            $journalEntry->lines()->create([
                                'account_id' => $counterpartId,
                                'cost_center_id' => $ccId,
                                'description' => "تسديد/إيراد - {$voucher->voucher_number}",
                                'debit' => 0,
                                'credit' => $amt,
                            ]);
                        } else {
                            $journalEntry->lines()->create([
                                'account_id' => $counterpartId,
                                'cost_center_id' => $ccId,
                                'description' => "دفع/مصروف - {$voucher->voucher_number}",
                                'debit' => $amt,
                                'credit' => 0,
                            ]);
                            $journalEntry->lines()->create([
                                'account_id' => $accId,
                                'cost_center_id' => $ccId,
                                'description' => "صرف نقدي/بنكي - {$voucher->voucher_number}",
                                'debit' => 0,
                                'credit' => $amt,
                            ]);
                        }
                    }
                }
            });

            return "Voucher #{$id} updated successfully:\n" . $voucher->fresh(['account', 'party', 'targetAccount', 'costCenter', 'journalEntry'])->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        } catch (\Throwable $e) {
            return "Error updating voucher: " . $e->getMessage();
        }
    }

    #[McpTool(name: 'delete_voucher', description: 'Delete a voucher by ID and cleanly revert its associated journal entry and check')]
    public function deleteVoucher(int $id): string
    {
        $voucher = Voucher::find($id);
        if (!$voucher) return "Error: Voucher with ID {$id} not found.";

        try {
            DB::transaction(function () use ($voucher) {
                Check::where('voucher_id', $voucher->id)->delete();
                if ($voucher->journal_entry_id) {
                    $entry = JournalEntry::find($voucher->journal_entry_id);
                    if ($entry) {
                        $entry->lines()->delete();
                        $entry->delete();
                    }
                }
                $voucher->delete();
            });

            return "Voucher #{$id} and its associated records deleted successfully.";
        } catch (\Throwable $e) {
            return "Error deleting voucher: " . $e->getMessage();
        }
    }

    // ==========================================
    // --- AL-ASEEL GOLDEN: CHECKS (الشيكات) ---
    // ==========================================

    #[McpTool(name: 'get_checks', description: 'Get a list of checks in portfolio (type: received, issued; status: under_collection, collected, endorsed, bounced, cancelled)')]
    public function getChecks(?string $type = null, ?string $status = null, int $limit = 20): string
    {
        $query = Check::with(['party', 'endorsedParty', 'currency'])->orderBy('due_date', 'asc');

        if ($type) $query->where('type', $type);
        if ($status) $query->where('status', $status);

        $checks = $query->take($limit)->get();
        if ($checks->isEmpty()) return "No checks found matching criteria.";
        return "Found " . $checks->count() . " checks:\n" . $checks->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_check', description: 'Create a new check in the checks portfolio')]
    public function createCheck(string $checkNumber, string $type, float $amount, string $bankName, string $dueDate, ?int $partyId = null, ?string $drawerName = null, ?string $notes = null): string
    {
        $currency = Currency::where('is_default', true)->first() ?? Currency::first();

        $check = Check::create([
            'check_number' => $checkNumber,
            'type' => in_array($type, ['received', 'issued']) ? $type : 'received',
            'bank_name' => $bankName,
            'drawer_name' => $drawerName,
            'due_date' => $dueDate,
            'issue_date' => date('Y-m-d'),
            'amount' => $amount,
            'currency_id' => $currency->id,
            'status' => 'under_collection',
            'party_id' => $partyId,
            'notes' => $notes,
        ]);

        return "Check created successfully with ID {$check->id}:\n" . $check->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'update_check_status', description: 'Update status of a check (under_collection, collected, endorsed, bounced, cancelled)')]
    public function updateCheckStatus(int $id, string $status, ?int $bankAccountId = null, ?int $endorsedPartyId = null, ?string $notes = null): string
    {
        $check = Check::find($id);
        if (!$check) return "Error: Check with ID {$id} not found.";

        if ($status === 'collected') {
            return $this->collectCheck($id, $bankAccountId);
        } elseif ($status === 'endorsed' && $endorsedPartyId) {
            return $this->endorseCheck($id, $endorsedPartyId);
        }

        $check->update([
            'status' => $status,
            'notes' => $notes ?? $check->notes,
        ]);

        return "Check #{$id} status updated to '{$status}'.\n" . $check->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'collect_check', description: 'Collect/deposit a received check into a bank account with automated journal entry')]
    public function collectCheck(int $id, ?int $bankAccountId = null): string
    {
        $check = Check::find($id);
        if (!$check) return "Error: Check with ID {$id} not found.";

        $bankAccount = $bankAccountId ? Account::find($bankAccountId) : (Account::where('code', '1102')->first() ?? Account::first());

        try {
            DB::transaction(function () use ($check, $bankAccount) {
                $check->status = 'collected';
                $check->collection_date = date('Y-m-d');

                if ($bankAccount && $check->type === 'received') {
                    $entry = JournalEntry::create([
                        'date' => date('Y-m-d'),
                        'reference' => 'CHK-COL-' . $check->check_number,
                        'description' => "تحصيل شيك وارد رقم {$check->check_number}",
                        'currency_id' => $check->currency_id,
                        'exchange_rate' => 1.0,
                    ]);

                    $entry->lines()->create([
                        'account_id' => $bankAccount->id,
                        'description' => "إيداع وتحصيل شيك {$check->check_number}",
                        'debit' => $check->amount,
                        'credit' => 0,
                    ]);

                    $bufferAccount = Account::where('code', '1101')->first() ?? $bankAccount;
                    $entry->lines()->create([
                        'account_id' => $bufferAccount->id,
                        'description' => "تحصيل شيك من الخزينة {$check->check_number}",
                        'debit' => 0,
                        'credit' => $check->amount,
                    ]);

                    $check->journal_entry_id = $entry->id;
                }

                $check->save();
            });

            return "Check #{$id} collected successfully into Bank account #{$bankAccount->id}.";
        } catch (\Throwable $e) {
            return "Error collecting check: " . $e->getMessage();
        }
    }

    #[McpTool(name: 'endorse_check', description: 'Endorse a received check to a vendor with automated debt payment journal entry')]
    public function endorseCheck(int $id, int $endorsedPartyId): string
    {
        $check = Check::find($id);
        if (!$check) return "Error: Check with ID {$id} not found.";

        $party = Party::find($endorsedPartyId);
        if (!$party) return "Error: Vendor/Party with ID {$endorsedPartyId} not found.";

        try {
            DB::transaction(function () use ($check, $party) {
                $check->status = 'endorsed';
                $check->endorsed_party_id = $party->id;

                $vendorAccount = $party->account_id ?? Account::where('code', '2101')->first()?->id;
                if ($vendorAccount) {
                    $entry = JournalEntry::create([
                        'date' => date('Y-m-d'),
                        'reference' => 'CHK-END-' . $check->check_number,
                        'description' => "تجيير شيك رقم {$check->check_number} إلى {$party->name}",
                        'currency_id' => $check->currency_id,
                        'exchange_rate' => 1.0,
                    ]);

                    $entry->lines()->create([
                        'account_id' => $vendorAccount,
                        'description' => "سداد بتجيير شيك {$check->check_number}",
                        'debit' => $check->amount,
                        'credit' => 0,
                    ]);

                    $bufferAccount = Account::where('code', '1101')->first()?->id ?? $vendorAccount;
                    $entry->lines()->create([
                        'account_id' => $bufferAccount,
                        'description' => "تجيير شيك برسم التحصيل {$check->check_number}",
                        'debit' => 0,
                        'credit' => $check->amount,
                    ]);

                    $check->journal_entry_id = $entry->id;
                }

                $check->save();
            });

            return "Check #{$id} endorsed successfully to {$party->name}.";
        } catch (\Throwable $e) {
            return "Error endorsing check: " . $e->getMessage();
        }
    }

    // ===============================================
    // --- AL-ASEEL GOLDEN: COST CENTERS (مراكز التكلفة) ---
    // ===============================================

    #[McpTool(name: 'get_cost_centers', description: 'Get a list of all cost centers')]
    public function getCostCenters(): string
    {
        $costCenters = CostCenter::with('parent')->orderBy('code')->get();
        if ($costCenters->isEmpty()) return "No cost centers found.";
        return "Found " . $costCenters->count() . " cost centers:\n" . $costCenters->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_cost_center', description: 'Create a new cost center in the cost centers tree')]
    public function createCostCenter(string $code, string $name, ?int $parentId = null, ?string $description = null): string
    {
        $cc = CostCenter::create([
            'code' => $code,
            'name' => $name,
            'parent_id' => $parentId,
            'description' => $description,
            'is_active' => true,
        ]);

        return "Cost center created successfully with ID {$cc->id}:\n" . $cc->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'update_cost_center', description: 'Update an existing cost center by ID')]
    public function updateCostCenter(int $id, ?string $name = null, ?string $code = null, ?int $parentId = null, ?bool $isActive = null): string
    {
        $cc = CostCenter::find($id);
        if (!$cc) return "Error: Cost center with ID {$id} not found.";

        $data = array_filter([
            'name' => $name,
            'code' => $code,
            'parent_id' => $parentId,
            'is_active' => $isActive,
        ], fn($v) => $v !== null);

        $cc->update($data);
        return "Cost center #{$id} updated successfully:\n" . $cc->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'delete_cost_center', description: 'Delete a cost center by ID')]
    public function deleteCostCenter(int $id): string
    {
        $cc = CostCenter::find($id);
        if (!$cc) return "Error: Cost center with ID {$id} not found.";

        try {
            $cc->delete();
            return "Cost center #{$id} deleted successfully.";
        } catch (\Throwable $e) {
            return "Error deleting cost center: " . $e->getMessage();
        }
    }

    // ====================================================
    // --- AL-ASEEL GOLDEN: STOCK TRANSFERS (حركات المخزون) ---
    // ====================================================

    #[McpTool(name: 'get_stock_transfers', description: 'Get a list of stock transfers and adjustments (type: transfer, stock_in, stock_out, adjustment)')]
    public function getStockTransfers(?string $type = null, int $limit = 20): string
    {
        $query = StockTransfer::with(['fromStore', 'toStore', 'lines.item'])->orderBy('date', 'desc');

        if ($type) $query->where('type', $type);

        $transfers = $query->take($limit)->get();
        if ($transfers->isEmpty()) return "No stock transfers found.";
        return "Found " . $transfers->count() . " stock transfers:\n" . $transfers->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_stock_transfer', description: 'Transfer items between two warehouses with automatic inventory stock updates')]
    public function createStockTransfer(int $fromStoreId, int $toStoreId, ?string $linesJson = null, ?string $date = null, ?string $notes = null): string
    {
        $linesData = is_array($linesJson) ? $linesJson : (json_decode($linesJson ?? '[]', true) ?? []);
        if (empty($linesData)) {
            $item = Item::first();
            if (!$item) return "Error: No items available in catalog.";
            $linesData = [['item_id' => $item->id, 'quantity' => 5, 'unit_cost' => (float)$item->purchase_price]];
        }

        $lastTransfer = StockTransfer::latest('id')->first();
        $nextNum = $lastTransfer ? ((int)substr($lastTransfer->transfer_number, 3) + 1) : 1;
        $transferNumber = 'TR-' . str_pad((string)$nextNum, 5, '0', STR_PAD_LEFT);

        try {
            $transfer = DB::transaction(function () use ($fromStoreId, $toStoreId, $linesData, $transferNumber, $date, $notes) {
                $transfer = StockTransfer::create([
                    'transfer_number' => $transferNumber,
                    'type' => 'transfer',
                    'from_store_id' => $fromStoreId,
                    'to_store_id' => $toStoreId,
                    'date' => $date ?? date('Y-m-d'),
                    'notes' => $notes,
                    'status' => 'completed',
                ]);

                foreach ($linesData as $line) {
                    $transfer->lines()->create([
                        'item_id' => $line['item_id'],
                        'quantity' => (float)$line['quantity'],
                        'unit_cost' => (float)($line['unit_cost'] ?? 0),
                    ]);

                    $qty = (float)$line['quantity'];

                    $from = StoreItem::firstOrCreate(['store_id' => $fromStoreId, 'item_id' => $line['item_id']], ['quantity' => 0]);
                    $from->quantity -= $qty;
                    $from->save();

                    $to = StoreItem::firstOrCreate(['store_id' => $toStoreId, 'item_id' => $line['item_id']], ['quantity' => 0]);
                    $to->quantity += $qty;
                    $to->save();
                }

                return $transfer->load(['fromStore', 'toStore', 'lines.item']);
            });

            return "Stock transfer created successfully with ID {$transfer->id}:\n" . $transfer->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        } catch (\Throwable $e) {
            return "Error creating stock transfer: " . $e->getMessage();
        }
    }

    #[McpTool(name: 'create_stock_adjustment', description: 'Make a stock adjustment or stock-in/stock-out in a store')]
    public function createStockAdjustment(int $storeId, ?string $linesJson = null, ?string $date = null, ?string $notes = null): string
    {
        $linesData = is_array($linesJson) ? $linesJson : (json_decode($linesJson ?? '[]', true) ?? []);
        if (empty($linesData)) {
            $item = Item::first();
            if (!$item) return "Error: No items available in catalog.";
            $linesData = [['item_id' => $item->id, 'quantity' => 1, 'unit_cost' => (float)$item->purchase_price]];
        }

        $lastTransfer = StockTransfer::latest('id')->first();
        $nextNum = $lastTransfer ? ((int)substr($lastTransfer->transfer_number, 3) + 1) : 1;
        $transferNumber = 'ADJ-' . str_pad((string)$nextNum, 5, '0', STR_PAD_LEFT);

        try {
            $transfer = DB::transaction(function () use ($storeId, $linesData, $transferNumber, $date, $notes) {
                $transfer = StockTransfer::create([
                    'transfer_number' => $transferNumber,
                    'type' => 'adjustment',
                    'to_store_id' => $storeId,
                    'date' => $date ?? date('Y-m-d'),
                    'notes' => $notes,
                    'status' => 'completed',
                ]);

                foreach ($linesData as $line) {
                    $qty = (float)$line['quantity'];
                    $transfer->lines()->create([
                        'item_id' => $line['item_id'],
                        'quantity' => $qty,
                        'unit_cost' => (float)($line['unit_cost'] ?? 0),
                    ]);

                    $storeItem = StoreItem::firstOrCreate(['store_id' => $storeId, 'item_id' => $line['item_id']], ['quantity' => 0]);
                    $storeItem->quantity += $qty;
                    $storeItem->save();
                }

                return $transfer->load(['toStore', 'lines.item']);
            });

            return "Stock adjustment completed successfully:\n" . $transfer->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        } catch (\Throwable $e) {
            return "Error adjusting stock: " . $e->getMessage();
        }
    }

    // =============================================
    // --- AL-ASEEL GOLDEN: QUOTATIONS (عروض الأسعار) ---
    // =============================================

    #[McpTool(name: 'get_quotations', description: 'Get a list of customer price quotations')]
    public function getQuotations(?string $status = null, int $limit = 20): string
    {
        $query = Quotation::with(['party', 'store', 'lines.item'])->orderBy('date', 'desc');
        if ($status) $query->where('status', $status);

        $quotes = $query->take($limit)->get();
        if ($quotes->isEmpty()) return "No quotations found.";
        return "Found " . $quotes->count() . " quotations:\n" . $quotes->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_quotation', description: 'Create a new price quotation / offer for a customer')]
    public function createQuotation(int $partyId, ?string $linesJson = null, ?int $storeId = null, float $discount = 0, ?string $date = null, ?string $expiryDate = null, ?string $notes = null): string
    {
        $linesData = is_array($linesJson) ? $linesJson : (json_decode($linesJson, true) ?? []);
        if (empty($linesData)) {
            $item = Item::first();
            if (!$item) return "Error: No items available in catalog.";
            $linesData = [['item_id' => $item->id, 'quantity' => 1, 'unit_price' => (float)$item->sales_price]];
        }

        $lastQuote = Quotation::latest('id')->first();
        $nextNum = $lastQuote ? ((int)substr($lastQuote->quotation_number, 4) + 1) : 1;
        $quotationNumber = 'QTN-' . str_pad((string)$nextNum, 5, '0', STR_PAD_LEFT);

        try {
            $quote = DB::transaction(function () use ($partyId, $storeId, $linesData, $discount, $quotationNumber, $date, $expiryDate, $notes) {
                $subtotal = 0;
                $processedLines = [];

                foreach ($linesData as $line) {
                    $qty = (float)$line['quantity'];
                    $price = (float)$line['unit_price'];
                    $total = $qty * $price;
                    $subtotal += $total;

                    $processedLines[] = [
                        'item_id' => $line['item_id'],
                        'quantity' => $qty,
                        'unit_price' => $price,
                        'total_price' => $total,
                    ];
                }

                $totalAmount = max(0, $subtotal - $discount);

                $quotation = Quotation::create([
                    'quotation_number' => $quotationNumber,
                    'party_id' => $partyId,
                    'store_id' => $storeId,
                    'date' => $date ?? date('Y-m-d'),
                    'expiry_date' => $expiryDate,
                    'status' => 'draft',
                    'subtotal' => $subtotal,
                    'discount' => $discount,
                    'total_amount' => $totalAmount,
                    'notes' => $notes,
                ]);

                foreach ($processedLines as $pLine) {
                    $quotation->lines()->create($pLine);
                }

                return $quotation->load(['party', 'store', 'lines.item']);
            });

            return "Quotation created successfully with ID {$quote->id}:\n" . $quote->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        } catch (\Throwable $e) {
            return "Error creating quotation: " . $e->getMessage();
        }
    }

    #[McpTool(name: 'convert_quotation_to_invoice', description: 'Convert a price quotation into a confirmed sales invoice with automated stock deduction and accounting entries')]
    public function convertQuotationToInvoice(int $id): string
    {
        $quotation = Quotation::with(['party', 'lines.item'])->find($id);
        if (!$quotation) return "Error: Quotation with ID {$id} not found.";
        if ($quotation->status === 'converted') return "Error: Quotation is already converted into invoice #{$quotation->converted_invoice_id}.";

        try {
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
                    'notes' => "Converted from Quotation #{$quotation->quotation_number}",
                ]);

                foreach ($quotation->lines as $line) {
                    $itemCost = (float)($line->item ? $line->item->purchase_price : 0);
                    $totalCost += $line->quantity * $itemCost;

                    $invoice->lines()->create([
                        'item_id' => $line->item_id,
                        'quantity' => $line->quantity,
                        'unit_price' => $line->unit_price,
                        'total_price' => $line->total_price,
                    ]);

                    if ($storeId) {
                        $storeItem = StoreItem::firstOrCreate(['store_id' => $storeId, 'item_id' => $line->item_id], ['quantity' => 0]);
                        $storeItem->quantity -= $line->quantity;
                        $storeItem->save();
                    }
                }

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

                $quotation->update(['status' => 'converted', 'converted_invoice_id' => $invoice->id]);
                return $invoice;
            });

            return "Quotation #{$id} converted successfully to Sales Invoice #{$invoice->id}.";
        } catch (\Throwable $e) {
            return "Error converting quotation: " . $e->getMessage();
        }
    }

    // ===============================================
    // --- AL-ASEEL GOLDEN: FIXED ASSETS (الأصول الثابتة) ---
    // ===============================================

    #[McpTool(name: 'get_fixed_assets', description: 'Get a list of fixed assets and their depreciation status')]
    public function getFixedAssets(): string
    {
        $assets = FixedAsset::with(['assetAccount', 'costCenter', 'depreciations'])->get();
        if ($assets->isEmpty()) return "No fixed assets found.";
        return "Found " . $assets->count() . " fixed assets:\n" . $assets->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_fixed_asset', description: 'Create a new fixed asset record')]
    public function createFixedAsset(string $code, string $name, float $purchaseCost, ?string $purchaseDate = null, float $usefulLifeYears = 5, float $salvageValue = 0, ?int $assetAccountId = null, ?int $costCenterId = null): string
    {
        $rate = $usefulLifeYears > 0 ? (100 / $usefulLifeYears) : 20;

        $asset = FixedAsset::create([
            'code' => $code,
            'name' => $name,
            'purchase_date' => $purchaseDate ?? date('Y-m-d'),
            'purchase_cost' => $purchaseCost,
            'salvage_value' => $salvageValue,
            'useful_life_years' => $usefulLifeYears,
            'depreciation_rate' => $rate,
            'depreciation_method' => 'straight_line',
            'asset_account_id' => $assetAccountId,
            'cost_center_id' => $costCenterId,
            'total_depreciated' => 0,
            'current_book_value' => $purchaseCost,
            'is_active' => true,
        ]);

        return "Fixed asset created successfully with ID {$asset->id}:\n" . $asset->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'calculate_depreciation', description: 'Calculate and post periodic depreciation for a fixed asset with automated journal entry')]
    public function calculateDepreciation(int $id, ?float $amount = null, ?string $date = null): string
    {
        $asset = FixedAsset::find($id);
        if (!$asset) return "Error: Fixed asset with ID {$id} not found.";

        $depreciationAmount = $amount;
        if (!$depreciationAmount) {
            $base = max(0, $asset->purchase_cost - $asset->salvage_value);
            $depreciationAmount = round($base * ($asset->depreciation_rate / 100), 2);
        }

        if ($asset->current_book_value - $depreciationAmount < $asset->salvage_value) {
            $depreciationAmount = max(0, $asset->current_book_value - $asset->salvage_value);
        }

        if ($depreciationAmount <= 0) {
            return "Error: Asset is already fully depreciated down to its salvage value.";
        }

        try {
            DB::transaction(function () use ($asset, $depreciationAmount, $date) {
                $depDate = $date ?? date('Y-m-d');
                $currency = Currency::where('is_default', true)->first() ?? Currency::first();
                $expenseAcc = $asset->depreciation_expense_account_id ?? Account::where('code', '5201')->first()?->id;
                $accumulatedAcc = $asset->accumulated_depreciation_account_id ?? $asset->asset_account_id;

                $entry = null;
                if ($expenseAcc && $accumulatedAcc && $currency) {
                    $entry = JournalEntry::create([
                        'date' => $depDate,
                        'reference' => 'DEP-' . $asset->code,
                        'description' => "إهلاك أصل ثابت: {$asset->name}",
                        'currency_id' => $currency->id,
                        'exchange_rate' => 1.0,
                    ]);

                    $entry->lines()->create([
                        'account_id' => $expenseAcc,
                        'cost_center_id' => $asset->cost_center_id,
                        'description' => "مصروف إهلاك {$asset->name}",
                        'debit' => $depreciationAmount,
                        'credit' => 0,
                    ]);

                    $entry->lines()->create([
                        'account_id' => $accumulatedAcc,
                        'cost_center_id' => $asset->cost_center_id,
                        'description' => "مجمع إهلاك {$asset->name}",
                        'debit' => 0,
                        'credit' => $depreciationAmount,
                    ]);
                }

                AssetDepreciation::create([
                    'fixed_asset_id' => $asset->id,
                    'date' => $depDate,
                    'amount' => $depreciationAmount,
                    'journal_entry_id' => $entry?->id,
                ]);

                $newTotal = $asset->total_depreciated + $depreciationAmount;
                $asset->update([
                    'total_depreciated' => $newTotal,
                    'current_book_value' => max($asset->salvage_value, $asset->purchase_cost - $newTotal),
                ]);
            });

            return "Depreciation of {$depreciationAmount} calculated and posted for asset {$asset->name} (#{$id}). New book value: {$asset->current_book_value}";
        } catch (\Throwable $e) {
            return "Error calculating depreciation: " . $e->getMessage();
        }
    }

    // ====================================================
    // --- AL-ASEEL GOLDEN: ADVANCED REPORTS (تقارير الأصيل) ---
    // ====================================================

    #[McpTool(name: 'get_aging_report', description: 'Get Debt Aging Analysis report for customers or vendors (type: customer, vendor)')]
    public function getAgingReport(?string $type = 'customer'): string
    {
        $type = in_array($type, ['customer', 'vendor']) ? $type : 'customer';
        $parties = Party::where('type', $type)->with('invoices')->get();
        $today = now();

        $aging = [];
        foreach ($parties as $party) {
            $pData = ['id' => $party->id, 'name' => $party->name, '0_30' => 0, '31_60' => 0, '61_90' => 0, 'over_90' => 0, 'total' => 0];
            foreach ($party->invoices as $inv) {
                $days = $today->diffInDays(\Carbon\Carbon::parse($inv->date));
                $amount = (float)$inv->total_amount;
                if ($days <= 30) $pData['0_30'] += $amount;
                elseif ($days <= 60) $pData['31_60'] += $amount;
                elseif ($days <= 90) $pData['61_90'] += $amount;
                else $pData['over_90'] += $amount;
                $pData['total'] += $amount;
            }
            if ($pData['total'] > 0) $aging[] = $pData;
        }

        return json_encode(['report' => 'Aging Analysis (' . ucfirst($type) . ')', 'data' => $aging], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_cost_centers_report', description: 'Get Cost Centers income & expense allocation report')]
    public function getCostCentersReport(?int $costCenterId = null): string
    {
        $query = JournalEntryLine::with(['costCenter', 'account', 'journalEntry'])->whereNotNull('cost_center_id');
        if ($costCenterId) $query->where('cost_center_id', $costCenterId);

        $lines = $query->get();
        $summary = [];

        foreach ($lines as $line) {
            $ccName = $line->costCenter?->name ?? 'Unknown CC';
            if (!isset($summary[$ccName])) {
                $summary[$ccName] = ['total_debit' => 0, 'total_credit' => 0, 'net_balance' => 0];
            }
            $summary[$ccName]['total_debit'] += (float)$line->debit;
            $summary[$ccName]['total_credit'] += (float)$line->credit;
            $summary[$ccName]['net_balance'] = $summary[$ccName]['total_debit'] - $summary[$ccName]['total_credit'];
        }

        return json_encode(['report' => 'Cost Centers Statement', 'data' => $summary], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_checks_report', description: 'Get Checks portfolio statistics and status overview')]
    public function getChecksReport(?string $type = null, ?string $status = null): string
    {
        $query = Check::with(['party', 'currency']);
        if ($type) $query->where('type', $type);
        if ($status) $query->where('status', $status);

        $checks = $query->get();
        $stats = [
            'total_received_amount' => Check::where('type', 'received')->sum('amount'),
            'total_issued_amount' => Check::where('type', 'issued')->sum('amount'),
            'under_collection_amount' => Check::where('status', 'under_collection')->sum('amount'),
            'collected_amount' => Check::where('status', 'collected')->sum('amount'),
            'checks_count' => $checks->count(),
        ];

        return json_encode(['report' => 'Checks Portfolio Report', 'stats' => $stats, 'checks' => $checks], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_inventory_valuation_report', description: 'Get Inventory Stock Valuation and quantities per warehouse')]
    public function getInventoryValuationReport(): string
    {
        $stores = Store::with(['storeItems.item'])->where('is_active', true)->get();
        $valuation = [];
        $totalSystemValue = 0;

        foreach ($stores as $store) {
            $storeTotal = 0;
            $itemsList = [];
            foreach ($store->storeItems as $si) {
                $item = $si->item;
                $cost = (float)($item ? $item->purchase_price : 0);
                $value = $si->quantity * $cost;
                $storeTotal += $value;
                $itemsList[] = [
                    'item_name' => $item?->name,
                    'quantity' => (float)$si->quantity,
                    'unit_cost' => $cost,
                    'total_value' => $value,
                ];
            }
            $totalSystemValue += $storeTotal;
            $valuation[] = [
                'store_name' => $store->name,
                'store_value' => $storeTotal,
                'items' => $itemsList,
            ];
        }

        return json_encode(['report' => 'Inventory Valuation Report', 'total_inventory_value' => $totalSystemValue, 'stores' => $valuation], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    // --- E-COMMERCE ORDERS & AI SALES ANALYTICS TOOLS ---

    protected function normalizeOrderStatus(?string $status): string
    {
        if (empty($status)) return 'shipped';
        $s = trim(mb_strtolower($status));
        if (in_array($s, ['shipped', 'delivering', 'out_for_delivery', 'شحن', 'تم الشحن', 'مشحون', 'توصيل', 'قيد التوصيل', 'بدنا نوصله', 'نوصله', 'ارسال', 'تم الارسال', 'جاري التوصيل', 'في الطريق'])) {
            return 'shipped';
        }
        if (in_array($s, ['delivered', 'completed', 'تسليم', 'تم التسليم', 'تم التوصيل', 'مسلم', 'واصل', 'مكتمل', 'تم استلامه', 'استلم'])) {
            return 'delivered';
        }
        if (in_array($s, ['processing', 'preparing', 'تجهيز', 'قيد التجهيز', 'جاري التجهيز', 'مجهز', 'في المستودع', 'تحضير'])) {
            return 'processing';
        }
        if (in_array($s, ['cancelled', 'canceled', 'rejected', 'الغاء', 'إلغاء', 'ملغي', 'مرفوض', 'الغيه', 'الغي'])) {
            return 'cancelled';
        }
        if (in_array($s, ['pending', 'waiting', 'انتظار', 'معلق', 'قيد الانتظار', 'جديد', 'غير مؤكد'])) {
            return 'pending';
        }
        return $s;
    }

    protected function findOrder(?string $identifier): ?Order
    {
        if (empty($identifier)) {
            return Order::with(['user', 'party', 'invoice.lines.item', 'items.item'])->latest()->first();
        }

        $clean = trim($identifier);
        $clean = preg_replace('/[#\s]+/', ' ', $clean);
        $clean = str_ireplace(['طلب رقم', 'طلب', 'order', 'no.', 'ORD-'], '', $clean);
        $clean = trim($clean);

        // 1. Direct Numeric ID match
        if (is_numeric($clean)) {
            $order = Order::with(['user', 'party', 'invoice.lines.item', 'items.item'])->find((int)$clean);
            if ($order) return $order;
        }

        // 2. Exact or partial Order Number match (e.g. ORD-20260830-101 or 101)
        $order = Order::with(['user', 'party', 'invoice.lines.item', 'items.item'])
            ->where('order_number', $clean)
            ->orWhere('order_number', 'like', "%{$clean}%")
            ->first();
        if ($order) return $order;

        // 3. Customer Shipping Name / User Name / Party Name match by full text or words
        $order = Order::with(['user', 'party', 'invoice.lines.item', 'items.item'])
            ->where('shipping_name', 'like', "%{$clean}%")
            ->orWhereHas('user', function($q) use ($clean) {
                $q->where('name', 'like', "%{$clean}%");
            })
            ->orWhereHas('party', function($q) use ($clean) {
                $q->where('name', 'like', "%{$clean}%");
            })
            ->latest()
            ->first();
        if ($order) return $order;

        // Try single keywords from customer name (e.g. 'محمود')
        $words = array_filter(explode(' ', $clean));
        foreach ($words as $word) {
            if (mb_strlen($word) >= 3) {
                $order = Order::with(['user', 'party', 'invoice.lines.item', 'items.item'])
                    ->where('shipping_name', 'like', "%{$word}%")
                    ->orWhereHas('user', function($q) use ($word) {
                        $q->where('name', 'like', "%{$word}%");
                    })
                    ->orWhereHas('party', function($q) use ($word) {
                        $q->where('name', 'like', "%{$word}%");
                    })
                    ->latest()
                    ->first();
                if ($order) return $order;
            }
        }

        // 4. Phone match
        $order = Order::with(['user', 'party', 'invoice.lines.item', 'items.item'])
            ->where('shipping_phone', 'like', "%{$clean}%")
            ->latest()
            ->first();
        if ($order) return $order;

        // 5. Fallback to latest active order
        return Order::with(['user', 'party', 'invoice.lines.item', 'items.item'])->latest()->first();
    }

    #[McpTool(name: 'get_orders', description: 'Get or search customer store orders. Filter by search query (customer name, phone, order number, product name) or status (pending, processing, shipped, delivered, cancelled)')]
    public function getOrders(?string $search = null, ?string $status = null, ?int $limit = 20): string
    {
        $query = Order::with(['user', 'party', 'invoice', 'items.item'])->latest();

        if ($status) {
            $normalizedStatus = $this->normalizeOrderStatus($status);
            $query->where('status', $normalizedStatus);
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('order_number', 'like', "%{$search}%")
                  ->orWhere('shipping_name', 'like', "%{$search}%")
                  ->orWhere('shipping_phone', 'like', "%{$search}%")
                  ->orWhereHas('items', function ($qi) use ($search) {
                      $qi->where('item_name', 'like', "%{$search}%");
                  });
            });
        }

        $orders = $query->take($limit ?? 20)->get();
        if ($orders->isEmpty()) return "No store orders found matching criteria.";

        return "Found " . $orders->count() . " store orders:\n" . $orders->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_order_details', description: 'Get detailed information for a specific order by its order number, ID, customer name (e.g. محمود عياش), or phone')]
    public function getOrderDetails(
        ?string $orderIdOrNumber = null,
        ?string $orderIdentifier = null,
        ?string $order_id = null
    ): string {
        $identifier = $orderIdOrNumber ?? ($orderIdentifier ?? ($order_id ?? null));
        $order = $this->findOrder($identifier);

        if (!$order) {
            return "Error: Order for '$identifier' not found. You can use 'get_orders' to list all orders.";
        }

        return "Order Details for #{$order->order_number} (Customer: {$order->shipping_name}):\n" . $order->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'update_order_status', description: 'Update the status of an online store order to shipped/delivering (بدنا نوصله / قيد التوصيل / تم الشحن), delivered (تم التسليم), processing (قيد التجهيز), cancelled (إلغاء), or pending. Accepts order number, ID, or customer name')]
    public function updateOrderStatus(
        ?string $orderIdOrNumber = null,
        ?string $orderIdentifier = null,
        ?string $order_id = null,
        ?string $newStatus = null,
        ?string $status = null,
        ?string $notes = null
    ): string {
        $identifier = $orderIdOrNumber ?? ($orderIdentifier ?? ($order_id ?? null));
        $rawStatus = $newStatus ?? ($status ?? 'shipped');

        $order = $this->findOrder($identifier);

        if (!$order) {
            return "Error: Order not found. Please specify customer name or order ID.";
        }

        $normalizedStatus = $this->normalizeOrderStatus($rawStatus);
        $allowed = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];

        if (!in_array($normalizedStatus, $allowed)) {
            $normalizedStatus = 'shipped';
        }

        $oldStatus = $order->status;

        DB::transaction(function () use ($order, $oldStatus, $normalizedStatus, $notes) {
            $order->status = $normalizedStatus;
            if ($notes) {
                $order->notes = ($order->notes ? $order->notes . " | " : "") . $notes;
            }

            if ($normalizedStatus === 'delivered' && $order->payment_method === 'cod') {
                $order->payment_status = 'paid';
            }

            // Restore warehouse inventory if cancelled
            if ($normalizedStatus === 'cancelled' && $oldStatus !== 'cancelled') {
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

        $statusArabic = match($normalizedStatus) {
            'shipped' => 'قيد التوصيل / تم الشحن (Shipped)',
            'delivered' => 'تم التسليم بنجاح (Delivered)',
            'processing' => 'قيد التجهيز بالمستودع (Processing)',
            'cancelled' => 'تم إلغاء الطلب واسترجاع المخزون (Cancelled)',
            default => 'قيد الانتظار (Pending)',
        };

        return "تم تحديث حالة طلب العميل ({$order->shipping_name}) رقم #{$order->order_number} بنجاح إلى: {$statusArabic}.";
    }

    #[McpTool(name: 'update_order', description: 'Full master tool to update any aspect of a customer order (status, customer name, phone, address, city, payment status, payment method, notes)')]
    public function updateOrder(
        ?string $orderIdOrNumber = null,
        ?string $orderIdentifier = null,
        ?string $order_id = null,
        ?string $status = null,
        ?string $newStatus = null,
        ?string $shippingName = null,
        ?string $shippingPhone = null,
        ?string $shippingAddress = null,
        ?string $shippingCity = null,
        ?string $paymentStatus = null,
        ?string $paymentMethod = null,
        ?string $notes = null
    ): string {
        $identifier = $orderIdOrNumber ?? ($orderIdentifier ?? ($order_id ?? null));
        $order = $this->findOrder($identifier);
        if (!$order) {
            return "Error: Order not found.";
        }

        $targetStatus = $newStatus ?? $status;

        DB::transaction(function () use ($order, $targetStatus, $shippingName, $shippingPhone, $shippingAddress, $shippingCity, $paymentStatus, $paymentMethod, $notes) {
            if ($targetStatus) {
                $normalized = $this->normalizeOrderStatus($targetStatus);
                $oldStatus = $order->status;
                $order->status = $normalized;

                if ($normalized === 'cancelled' && $oldStatus !== 'cancelled') {
                    foreach ($order->items as $itemLine) {
                        if ($itemLine->item_id) {
                            $si = StoreItem::where('item_id', $itemLine->item_id)->first();
                            if ($si) $si->increment('quantity', $itemLine->quantity);
                        }
                    }
                }
            }
            if ($shippingName) $order->shipping_name = $shippingName;
            if ($shippingPhone) $order->shipping_phone = $shippingPhone;
            if ($shippingAddress) $order->shipping_address = $shippingAddress;
            if ($shippingCity) $order->shipping_city = $shippingCity;
            if ($paymentStatus) $order->payment_status = $paymentStatus;
            if ($paymentMethod) $order->payment_method = $paymentMethod;
            if ($notes) {
                $order->notes = ($order->notes ? $order->notes . " | " : "") . $notes;
            }

            $order->save();
        });

        return "تم تحديث بيانات الطلب #{$order->order_number} الخاص بالعميل ({$order->shipping_name}) بنجاح.";
    }

    #[McpTool(name: 'delete_order', description: 'Delete a customer order by order number, ID, or customer name')]
    public function deleteOrder(
        ?string $orderIdOrNumber = null,
        ?string $orderIdentifier = null,
        ?string $order_id = null
    ): string {
        $identifier = $orderIdOrNumber ?? ($orderIdentifier ?? ($order_id ?? null));
        $order = $this->findOrder($identifier);
        if (!$order) {
            return "Error: Order not found.";
        }

        $orderNumber = $order->order_number;
        $order->delete();

        return "تم حذف الطلب رقم #{$orderNumber} بنجاح.";
    }

    #[McpTool(name: 'verify_order_payment_receipt', description: 'Inspect and verify customer payment transfer screenshot proof (بنك فلسطين / جوال باي / بال باي) for an order, and update payment status to paid or unpaid')]
    public function verifyOrderPaymentReceipt(
        ?string $orderIdOrNumber = null,
        ?string $orderIdentifier = null,
        ?string $order_id = null,
        ?bool $isVerified = true,
        ?string $notes = null
    ): string {
        $identifier = $orderIdOrNumber ?? ($orderIdentifier ?? ($order_id ?? null));
        $order = $this->findOrder($identifier);

        if (!$order) {
            return "Error: Order not found.";
        }

        $verified = $isVerified ?? true;

        $order->update([
            'is_payment_verified' => $verified,
            'payment_status' => $verified ? 'paid' : 'unpaid',
            'notes' => ($order->notes ? $order->notes . " | " : "") . ($notes ?? ($verified ? 'تم التحقق من إشعار وسكرين شوت الدفع واعتماد السداد من الـ MCP' : 'تم إلغاء اعتماد الدفع')),
        ]);

        $receiptInfo = $order->payment_receipt_url ? "رابط الإشعار المرفق: {$order->payment_receipt_url}" : "لا يوجد إشعار مرفق.";

        return "تم تحديث حالة التحقق من دفع الطلب #{$order->order_number} بنجاح.\nحالة الدفع: " . ($verified ? 'مدفوع ومؤكد (PAID ✅)' : 'غير مدفوع (UNPAID ⏳)') . "\n{$receiptInfo}";
    }

    // --- DELIVERY ZONES & CUSTOMER SUGGESTIONS MCP TOOLS ---

    #[McpTool(name: 'get_delivery_zones', description: 'Get a list of all configured delivery zones and their shipping rates (₪) across Palestinian cities with optional city filter')]
    public function getDeliveryZones(?string $city = null, ?bool $activeOnly = true): string
    {
        $query = \App\Models\DeliveryZone::query();

        if ($activeOnly ?? true) {
            $query->where('is_active', true)->where('is_approved', true);
        }

        if ($city) {
            $query->where('city', 'like', "%{$city}%");
        }

        $zones = $query->orderBy('city')->orderBy('delivery_fee')->get();

        if ($zones->isEmpty()) return "No delivery zones found matching criteria.";

        return "Found {$zones->count()} Delivery Zones:\n" . $zones->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_delivery_zone', description: 'Create a new delivery zone with custom delivery fee (₪), city, and estimated delivery time')]
    public function createDeliveryZone(
        string $name,
        float $deliveryFee,
        ?string $city = 'غزة',
        ?string $estimatedTime = 'خلال 24-48 ساعة',
        ?string $notes = null
    ): string {
        $zone = \App\Models\DeliveryZone::create([
            'name' => $name,
            'city' => $city ?? 'غزة',
            'delivery_fee' => $deliveryFee,
            'estimated_time' => $estimatedTime ?? 'خلال 24-48 ساعة',
            'is_active' => true,
            'is_approved' => true,
            'status' => 'approved',
            'admin_notes' => $notes,
        ]);

        return "تمت إضافة منطقة التوصيل الجديدة ({$zone->name}) بسعر توصيل {$zone->delivery_fee} ₪ بنجاح (ID: {$zone->id}).";
    }

    #[McpTool(name: 'update_delivery_zone', description: 'Update an existing delivery zone (fee, name, city, active status, estimated time) by ID or name')]
    public function updateDeliveryZone(
        string|int $zoneIdOrName,
        ?float $deliveryFee = null,
        ?string $name = null,
        ?string $city = null,
        ?bool $isActive = null,
        ?string $estimatedTime = null
    ): string {
        $zone = \App\Models\DeliveryZone::where('id', $zoneIdOrName)
            ->orWhere('name', 'like', "%{$zoneIdOrName}%")
            ->first();

        if (!$zone) {
            return "Error: Delivery zone '$zoneIdOrName' not found.";
        }

        if ($deliveryFee !== null) $zone->delivery_fee = $deliveryFee;
        if ($name !== null) $zone->name = $name;
        if ($city !== null) $zone->city = $city;
        if ($isActive !== null) $zone->is_active = $isActive;
        if ($estimatedTime !== null) $zone->estimated_time = $estimatedTime;

        $zone->save();

        return "تم تحديث بيانات منطقة التوصيل ({$zone->name}) بنجاح. السعر الحالي: {$zone->delivery_fee} ₪ | الحالة: " . ($zone->is_active ? 'مفعلة' : 'معطلة');
    }

    #[McpTool(name: 'delete_delivery_zone', description: 'Delete a delivery zone by ID or name')]
    public function deleteDeliveryZone(string|int $zoneIdOrName): string
    {
        $zone = \App\Models\DeliveryZone::where('id', $zoneIdOrName)
            ->orWhere('name', 'like', "%{$zoneIdOrName}%")
            ->first();

        if (!$zone) {
            return "Error: Delivery zone '$zoneIdOrName' not found.";
        }

        $zoneName = $zone->name;
        $zone->delete();

        return "تم حذف منطقة التوصيل ({$zoneName}) بنجاح.";
    }

    #[McpTool(name: 'get_suggested_delivery_zones', description: 'List customer suggested delivery zones awaiting admin review and approval')]
    public function getSuggestedDeliveryZones(?string $status = 'pending'): string
    {
        $query = \App\Models\DeliveryZone::with('suggestedByUser');

        if ($status) {
            $query->where('status', $status);
        }

        $suggestions = $query->latest()->get();

        if ($suggestions->isEmpty()) return "No customer zone suggestions found with status '$status'.";

        return "Found {$suggestions->count()} Zone Suggestions:\n" . $suggestions->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'approve_suggested_delivery_zone', description: 'Approve a customer-suggested delivery zone, set its shipping fee (₪), and activate it for all store shoppers')]
    public function approveSuggestedDeliveryZone(
        string|int $zoneIdOrName,
        float $deliveryFee,
        ?string $adminNotes = null
    ): string {
        $zone = \App\Models\DeliveryZone::where('id', $zoneIdOrName)
            ->orWhere('name', 'like', "%{$zoneIdOrName}%")
            ->first();

        if (!$zone) {
            return "Error: Zone suggestion '$zoneIdOrName' not found.";
        }

        $zone->update([
            'delivery_fee' => $deliveryFee,
            'is_active' => true,
            'is_approved' => true,
            'status' => 'approved',
            'admin_notes' => $adminNotes ?? 'تم الاعتماد والتفعيل عبر الـ MCP AI.',
        ]);

        return "تم اعتماد وتفعيل منطقة التوصيل المقترحة ({$zone->name}) بنجاح بسعر توصيل {$deliveryFee} ₪.";
    }

    #[McpTool(name: 'reject_suggested_delivery_zone', description: 'Reject a customer-suggested delivery zone')]
    public function rejectSuggestedDeliveryZone(
        string|int $zoneIdOrName,
        ?string $reason = null
    ): string {
        $zone = \App\Models\DeliveryZone::where('id', $zoneIdOrName)
            ->orWhere('name', 'like', "%{$zoneIdOrName}%")
            ->first();

        if (!$zone) {
            return "Error: Zone suggestion '$zoneIdOrName' not found.";
        }

        $zone->update([
            'is_active' => false,
            'status' => 'rejected',
            'admin_notes' => $reason ?? 'تم رفض الاقتراح.',
        ]);

        return "تم رفض اقتراح منطقة التوصيل ({$zone->name}).";
    }

    // --- PAYMENT TRANSFER METHODS (طرق وحسابات التحويل البنكي والمحافظ المعتمدة) MCP TOOLS ---

    #[McpTool(name: 'get_payment_transfer_methods', description: 'Get list of all admin-configured transfer payment methods (Bank of Palestine, Jawwal Pay, PalPay, Merchant accounts, IBANs, phone numbers, notes, logos)')]
    public function getPaymentTransferMethods(?bool $activeOnly = true): string
    {
        $query = \App\Models\TransferMethod::query();

        if ($activeOnly ?? true) {
            $query->where('is_active', true);
        }

        $methods = $query->orderBy('sort_order')->orderBy('id')->get();

        if ($methods->isEmpty()) return "No transfer payment methods found.";

        return "Found {$methods->count()} Transfer Payment Methods:\n" . $methods->toJson(JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'create_payment_transfer_method', description: 'Create a new transfer payment method (bank account, digital wallet, or merchant transfer) with custom details, IBAN, phone, notes/instructions, and logo URL')]
    public function createPaymentTransferMethod(
        string $name,
        ?string $accountName = null,
        ?string $accountNumber = null,
        ?string $iban = null,
        ?string $phone = null,
        ?string $instructions = null,
        ?string $logoUrl = null
    ): string {
        $method = \App\Models\TransferMethod::create([
            'name' => $name,
            'account_name' => $accountName,
            'account_number' => $accountNumber,
            'iban' => $iban,
            'phone' => $phone,
            'instructions' => $instructions,
            'logo_url' => $logoUrl,
            'is_active' => true,
            'sort_order' => (\App\Models\TransferMethod::max('sort_order') ?? 0) + 1,
        ]);

        return "تمت إضافة طريقة التحويل الجديدة ({$method->name}) بنجاح (ID: {$method->id}).";
    }

    #[McpTool(name: 'update_payment_transfer_method', description: 'Update an existing transfer payment method by ID or name (name, account details, IBAN, phone, custom instructions, logo, active status)')]
    public function updatePaymentTransferMethod(
        string|int $methodIdOrName,
        ?string $name = null,
        ?string $accountName = null,
        ?string $accountNumber = null,
        ?string $iban = null,
        ?string $phone = null,
        ?string $instructions = null,
        ?string $logoUrl = null,
        ?bool $isActive = null
    ): string {
        $method = \App\Models\TransferMethod::where('id', $methodIdOrName)
            ->orWhere('name', 'like', "%{$methodIdOrName}%")
            ->first();

        if (!$method) {
            return "Error: Transfer method '$methodIdOrName' not found.";
        }

        if ($name !== null) $method->name = $name;
        if ($accountName !== null) $method->account_name = $accountName;
        if ($accountNumber !== null) $method->account_number = $accountNumber;
        if ($iban !== null) $method->iban = $iban;
        if ($phone !== null) $method->phone = $phone;
        if ($instructions !== null) $method->instructions = $instructions;
        if ($logoUrl !== null) $method->logo_url = $logoUrl;
        if ($isActive !== null) $method->is_active = $isActive;

        $method->save();

        return "تم تحديث بيانات طريقة التحويل ({$method->name}) بنجاح. الحالة: " . ($method->is_active ? 'مفعلة' : 'معطلة');
    }

    #[McpTool(name: 'delete_payment_transfer_method', description: 'Delete a transfer payment method by ID or name')]
    public function deletePaymentTransferMethod(string|int $methodIdOrName): string
    {
        $method = \App\Models\TransferMethod::where('id', $methodIdOrName)
            ->orWhere('name', 'like', "%{$methodIdOrName}%")
            ->first();

        if (!$method) {
            return "Error: Transfer method '$methodIdOrName' not found.";
        }

        $methodName = $method->name;
        $method->delete();

        return "تم حذف طريقة التحويل ({$methodName}) بنجاح.";
    }

    #[McpTool(name: 'analyze_orders_sales', description: 'Comprehensive AI Sales & Ecommerce Performance Analytics (revenue, top products, conversion rates, order status breakdown, city performance)')]
    public function analyzeOrdersSales(?string $period = 'all'): string
    {
        $query = Order::query();

        if ($period === 'today') {
            $query->whereDate('created_at', now()->toDateString());
        } elseif ($period === 'week') {
            $query->where('created_at', '>=', now()->subDays(7));
        } elseif ($period === 'month') {
            $query->where('created_at', '>=', now()->subDays(30));
        }

        $allOrders = $query->with('items')->get();
        $nonCancelled = $allOrders->where('status', '!=', 'cancelled');

        $totalRevenue = $nonCancelled->sum('total_amount');
        $totalOrdersCount = $allOrders->count();
        $avgOrderValue = $totalOrdersCount > 0 ? ($totalRevenue / max(1, $nonCancelled->count())) : 0;

        // Status breakdown
        $statusBreakdown = [
            'pending' => $allOrders->where('status', 'pending')->count(),
            'processing' => $allOrders->where('status', 'processing')->count(),
            'shipped' => $allOrders->where('status', 'shipped')->count(),
            'delivered' => $allOrders->where('status', 'delivered')->count(),
            'cancelled' => $allOrders->where('status', 'cancelled')->count(),
        ];

        // Top selling products
        $productSales = [];
        foreach ($nonCancelled as $ord) {
            foreach ($ord->items as $line) {
                $name = $line->item_name;
                if (!isset($productSales[$name])) {
                    $productSales[$name] = ['units_sold' => 0, 'total_revenue' => 0];
                }
                $productSales[$name]['units_sold'] += $line->quantity;
                $productSales[$name]['total_revenue'] += $line->total_price;
            }
        }
        uasort($productSales, fn($a, $b) => $b['total_revenue'] <=> $a['total_revenue']);
        $topProducts = array_slice($productSales, 0, 5, true);

        // Sales by payment method
        $paymentMethods = [
            'cod' => $nonCancelled->where('payment_method', 'cod')->sum('total_amount'),
            'card' => $nonCancelled->where('payment_method', 'card')->sum('total_amount'),
            'bank_transfer' => $nonCancelled->where('payment_method', 'bank_transfer')->sum('total_amount'),
        ];

        $analysis = [
            'report_title' => 'E-commerce Store Sales & Order Performance Analysis',
            'period' => $period,
            'summary_metrics' => [
                'total_orders' => $totalOrdersCount,
                'successful_orders' => $nonCancelled->count(),
                'total_sales_revenue' => round($totalRevenue, 2),
                'average_order_value' => round($avgOrderValue, 2),
                'currency' => 'ILS (₪)',
            ],
            'order_status_distribution' => $statusBreakdown,
            'top_selling_products' => $topProducts,
            'sales_by_payment_method' => $paymentMethods,
        ];

        return json_encode($analysis, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    // --- FINANCIAL STATEMENTS & ADVANCED ERP REPORT TOOLS ---

    #[McpTool(name: 'get_account_statement', description: 'Get detailed Account Statement (كشف حساب تفصيلي) for any ledger account with running balance')]
    public function getAccountStatement(string|int $accountIdOrCode, ?string $fromDate = null, ?string $toDate = null): string
    {
        $account = Account::where('id', $accountIdOrCode)->orWhere('code', $accountIdOrCode)->first();
        if (!$account) {
            return "Error: Account '$accountIdOrCode' not found.";
        }

        $query = JournalEntryLine::with('journalEntry')
            ->where('account_id', $account->id)
            ->join('journal_entries', 'journal_entry_lines.journal_entry_id', '=', 'journal_entries.id')
            ->orderBy('journal_entries.date')
            ->select('journal_entry_lines.*');

        if ($fromDate) $query->where('journal_entries.date', '>=', $fromDate);
        if ($toDate) $query->where('journal_entries.date', '<=', $toDate);

        $lines = $query->get();
        $totalDebit = 0;
        $totalCredit = 0;
        $balance = 0;
        $statement = [];

        foreach ($lines as $line) {
            $totalDebit += (float)$line->debit;
            $totalCredit += (float)$line->credit;

            if ($account->balance_type === 'debit') {
                $balance += ($line->debit - $line->credit);
            } else {
                $balance += ($line->credit - $line->debit);
            }

            $statement[] = [
                'date' => $line->journalEntry?->date,
                'reference' => $line->journalEntry?->reference,
                'description' => $line->description ?: $line->journalEntry?->description,
                'debit' => (float)$line->debit,
                'credit' => (float)$line->credit,
                'running_balance' => round($balance, 2),
            ];
        }

        $result = [
            'account' => [
                'id' => $account->id,
                'code' => $account->code,
                'name' => $account->name,
                'type' => $account->type,
                'nature' => $account->balance_type,
            ],
            'period' => ['from' => $fromDate, 'to' => $toDate],
            'summary' => [
                'total_debit' => round($totalDebit, 2),
                'total_credit' => round($totalCredit, 2),
                'final_balance' => round($balance, 2),
            ],
            'entries' => $statement,
        ];

        return json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_trial_balance', description: 'Get Trial Balance (ميزان المراجعة بالمجاميع والأرصدة) for all ledger accounts')]
    public function getTrialBalance(?string $fromDate = null, ?string $toDate = null): string
    {
        $accountsQuery = Account::query();
        $applyFilters = function($q) use ($fromDate, $toDate) {
            if ($fromDate || $toDate) {
                $q->whereHas('journalEntry', function($jeQuery) use ($fromDate, $toDate) {
                    if ($fromDate) $jeQuery->where('date', '>=', $fromDate);
                    if ($toDate) $jeQuery->where('date', '<=', $toDate);
                });
            }
        };

        $accounts = $accountsQuery->withSum(['journalEntryLines as total_debit' => $applyFilters], 'debit')
                                  ->withSum(['journalEntryLines as total_credit' => $applyFilters], 'credit')
                                  ->get();

        $rows = [];
        $sumDebit = 0;
        $sumCredit = 0;

        foreach ($accounts as $account) {
            $debit = (float)($account->total_debit ?? 0);
            $credit = (float)($account->total_credit ?? 0);
            $balance = 0;
            $balanceType = '';

            if ($debit > $credit) {
                $balance = $debit - $credit;
                $balanceType = 'debit';
                $sumDebit += $balance;
            } elseif ($credit > $debit) {
                $balance = $credit - $debit;
                $balanceType = 'credit';
                $sumCredit += $balance;
            }

            if ($debit > 0 || $credit > 0) {
                $rows[] = [
                    'code' => $account->code,
                    'name' => $account->name,
                    'total_debit' => $debit,
                    'total_credit' => $credit,
                    'balance' => round($balance, 2),
                    'balance_type' => $balanceType,
                ];
            }
        }

        $result = [
            'report' => 'Trial Balance (ميزان المراجعة)',
            'period' => ['from' => $fromDate, 'to' => $toDate],
            'total_debit_balance' => round($sumDebit, 2),
            'total_credit_balance' => round($sumCredit, 2),
            'is_balanced' => abs($sumDebit - $sumCredit) < 0.01,
            'accounts' => $rows,
        ];

        return json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_income_statement', description: 'Get Income Statement (قائمة الدخل - الأرباح والخسائر) with revenue, COGS, expenses, and Net Profit')]
    public function getIncomeStatement(?string $fromDate = null, ?string $toDate = null): string
    {
        $applyFilters = function($q) use ($fromDate, $toDate) {
            if ($fromDate || $toDate) {
                $q->whereHas('journalEntry', function($jeQuery) use ($fromDate, $toDate) {
                    if ($fromDate) $jeQuery->where('date', '>=', $fromDate);
                    if ($toDate) $jeQuery->where('date', '<=', $toDate);
                });
            }
        };

        $revenues = Account::where('type', 'revenue')
            ->withSum(['journalEntryLines as total_debit' => $applyFilters], 'debit')
            ->withSum(['journalEntryLines as total_credit' => $applyFilters], 'credit')
            ->get();

        $expenses = Account::where('type', 'expense')
            ->withSum(['journalEntryLines as total_debit' => $applyFilters], 'debit')
            ->withSum(['journalEntryLines as total_credit' => $applyFilters], 'credit')
            ->get();

        $totalRevenue = 0;
        $revenueDetails = [];
        foreach ($revenues as $rev) {
            $bal = (float)(($rev->total_credit ?? 0) - ($rev->total_debit ?? 0));
            if ($bal != 0) {
                $revenueDetails[] = ['code' => $rev->code, 'name' => $rev->name, 'amount' => round($bal, 2)];
                $totalRevenue += $bal;
            }
        }

        $totalExpense = 0;
        $expenseDetails = [];
        foreach ($expenses as $exp) {
            $bal = (float)(($exp->total_debit ?? 0) - ($exp->total_credit ?? 0));
            if ($bal != 0) {
                $expenseDetails[] = ['code' => $exp->code, 'name' => $exp->name, 'amount' => round($bal, 2)];
                $totalExpense += $bal;
            }
        }

        $netIncome = $totalRevenue - $totalExpense;

        $result = [
            'report' => 'Income Statement (قائمة الدخل)',
            'period' => ['from' => $fromDate, 'to' => $toDate],
            'total_revenue' => round($totalRevenue, 2),
            'total_expenses' => round($totalExpense, 2),
            'net_profit' => round($netIncome, 2),
            'profit_status' => $netIncome >= 0 ? 'ربح صافي (Profit)' : 'خسارة (Loss)',
            'revenue_breakdown' => $revenueDetails,
            'expense_breakdown' => $expenseDetails,
        ];

        return json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_party_statement', description: 'Get detailed statement for any customer or vendor (كشف حساب عميل أو مورد) with invoices and payments')]
    public function getPartyStatement(string|int $partyIdOrName, ?string $fromDate = null, ?string $toDate = null): string
    {
        $party = Party::with('account')
            ->where('id', $partyIdOrName)
            ->orWhere('name', 'like', "%{$partyIdOrName}%")
            ->first();

        if (!$party) {
            return "Error: Customer/Vendor '$partyIdOrName' not found.";
        }

        $balance = 0;
        if ($party->account_id) {
            $debit = DB::table('journal_entry_lines')->where('account_id', $party->account_id)->sum('debit');
            $credit = DB::table('journal_entry_lines')->where('account_id', $party->account_id)->sum('credit');
            $balance = ($party->type === 'customer') ? ($debit - $credit) : ($credit - $debit);
        }

        $invoicesQuery = Invoice::where('party_id', $party->id)->with(['lines.item', 'store'])->latest();
        if ($fromDate) $invoicesQuery->where('date', '>=', $fromDate);
        if ($toDate) $invoicesQuery->where('date', '<=', $toDate);
        $invoices = $invoicesQuery->get();

        $vouchersQuery = Voucher::where('party_id', $party->id)->latest();
        if ($fromDate) $vouchersQuery->where('date', '>=', $fromDate);
        if ($toDate) $vouchersQuery->where('date', '<=', $toDate);
        $vouchers = $vouchersQuery->get();

        $result = [
            'party' => [
                'id' => $party->id,
                'name' => $party->name,
                'type' => $party->type,
                'phone' => $party->phone,
                'address' => $party->address,
                'current_balance' => round((float)$balance, 2),
                'balance_status' => $balance > 0 ? 'مدين (مستحق عليه)' : ($balance < 0 ? 'دائن (له رصيد)' : 'خالص (0)'),
            ],
            'invoices_count' => $invoices->count(),
            'invoices' => $invoices,
            'vouchers' => $vouchers,
        ];

        return json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_stock_movement_report', description: 'Get detailed Stock Movement & Card report (حركة صنف ومخزون) for any product')]
    public function getStockMovementReport(string|int $itemIdOrBarcode, ?string $fromDate = null, ?string $toDate = null): string
    {
        $item = Item::with('category')
            ->where('id', $itemIdOrBarcode)
            ->orWhere('barcode', $itemIdOrBarcode)
            ->orWhere('name', 'like', "%{$itemIdOrBarcode}%")
            ->first();

        if (!$item) {
            return "Error: Product '$itemIdOrBarcode' not found.";
        }

        // Purchases (in)
        $purchases = DB::table('invoice_lines')
            ->join('invoices', 'invoice_lines.invoice_id', '=', 'invoices.id')
            ->where('invoice_lines.item_id', $item->id)
            ->whereIn('invoices.type', ['purchase', 'sale_return'])
            ->select('invoices.date', 'invoices.type', 'invoices.id as invoice_id', 'invoice_lines.quantity', 'invoice_lines.unit_price')
            ->get();

        // Sales (out)
        $sales = DB::table('invoice_lines')
            ->join('invoices', 'invoice_lines.invoice_id', '=', 'invoices.id')
            ->where('invoice_lines.item_id', $item->id)
            ->whereIn('invoices.type', ['sale', 'purchase_return'])
            ->select('invoices.date', 'invoices.type', 'invoices.id as invoice_id', 'invoice_lines.quantity', 'invoice_lines.unit_price')
            ->get();

        $totalIn = $purchases->sum('quantity');
        $totalOut = $sales->sum('quantity');
        $currentStock = StoreItem::where('item_id', $item->id)->sum('quantity');

        $result = [
            'item' => [
                'id' => $item->id,
                'name' => $item->name,
                'barcode' => $item->barcode,
                'category' => $item->category?->name,
                'purchase_price' => $item->purchase_price,
                'sales_price' => $item->sales_price,
                'current_stock_on_hand' => (float)$currentStock,
            ],
            'movement_summary' => [
                'total_quantity_received' => (float)$totalIn,
                'total_quantity_sold_out' => (float)$totalOut,
                'net_movement' => (float)($totalIn - $totalOut),
            ],
            'recent_inbound_transactions' => $purchases->take(10),
            'recent_outbound_transactions' => $sales->take(10),
        ];

        return json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    #[McpTool(name: 'get_dashboard_summary', description: 'Get Executive ERP Dashboard Summary with total cash balances, receivables, payables, inventory value, and order metrics')]
    public function getDashboardSummary(): string
    {
        $cashBoxAccount = Account::where('code', '1101')->first();
        $bankAccount = Account::where('code', '1102')->first();
        $arAccount = Account::where('code', '1103')->first();
        $apAccount = Account::where('code', '2101')->first();

        $getBalance = function($acc) {
            if (!$acc) return 0;
            $debit = DB::table('journal_entry_lines')->where('account_id', $acc->id)->sum('debit');
            $credit = DB::table('journal_entry_lines')->where('account_id', $acc->id)->sum('credit');
            return $acc->balance_type === 'debit' ? ($debit - $credit) : ($credit - $debit);
        };

        $cashBalance = $getBalance($cashBoxAccount);
        $bankBalance = $getBalance($bankAccount);
        $receivables = $getBalance($arAccount);
        $payables = $getBalance($apAccount);

        $totalStoresValue = 0;
        foreach (StoreItem::with('item')->get() as $si) {
            $cost = (float)($si->item ? $si->item->purchase_price : 0);
            $totalStoresValue += ($si->quantity * $cost);
        }

        $totalOrders = Order::count();
        $pendingOrders = Order::where('status', 'pending')->count();
        $onlineRevenue = Order::where('status', '!=', 'cancelled')->sum('total_amount');

        $summary = [
            'system_title' => 'Rentisy Accounting ERP Executive Dashboard',
            'timestamp' => now()->toDateTimeString(),
            'financial_liquidity' => [
                'cash_in_hand_ILS' => round((float)$cashBalance, 2),
                'bank_balance_ILS' => round((float)$bankBalance, 2),
                'total_available_liquidity_ILS' => round((float)($cashBalance + $bankBalance), 2),
            ],
            'debt_position' => [
                'total_receivables_due_from_customers_ILS' => round((float)$receivables, 2),
                'total_payables_due_to_suppliers_ILS' => round((float)$payables, 2),
                'net_debt_position_ILS' => round((float)($receivables - $payables), 2),
            ],
            'inventory_asset_valuation_ILS' => round((float)$totalStoresValue, 2),
            'ecommerce_operations' => [
                'total_orders' => $totalOrders,
                'pending_orders_waiting_action' => $pendingOrders,
                'online_sales_revenue_ILS' => round((float)$onlineRevenue, 2),
            ],
        ];

        return json_encode($summary, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }
}
