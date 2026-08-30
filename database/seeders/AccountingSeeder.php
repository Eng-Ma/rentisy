<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Currency;
use App\Models\Account;

class AccountingSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Currencies
        Currency::updateOrCreate(
            ['code' => 'ILS'],
            ['name' => 'شيكل إسرائيلي', 'exchange_rate' => 1.0, 'is_default' => true]
        );
        Currency::updateOrCreate(
            ['code' => 'USD'],
            ['name' => 'دولار أمريكي', 'exchange_rate' => 3.75, 'is_default' => false]
        );
        Currency::updateOrCreate(
            ['code' => 'JOD'],
            ['name' => 'دينار أردني', 'exchange_rate' => 5.28, 'is_default' => false]
        );

        // 2. Chart of Accounts (Basic Tree)
        $assets = Account::updateOrCreate(
            ['code' => '1'],
            ['name' => 'الأصول', 'type' => 'asset', 'balance_type' => 'debit']
        );
        $liabilities = Account::updateOrCreate(
            ['code' => '2'],
            ['name' => 'الخصوم', 'type' => 'liability', 'balance_type' => 'credit']
        );
        $equity = Account::updateOrCreate(
            ['code' => '3'],
            ['name' => 'حقوق الملكية', 'type' => 'equity', 'balance_type' => 'credit']
        );
        $revenue = Account::updateOrCreate(
            ['code' => '4'],
            ['name' => 'الإيرادات', 'type' => 'revenue', 'balance_type' => 'credit']
        );
        $expenses = Account::updateOrCreate(
            ['code' => '5'],
            ['name' => 'المصروفات', 'type' => 'expense', 'balance_type' => 'debit']
        );

        // Current Assets
        $currentAssets = Account::updateOrCreate(
            ['code' => '11'],
            ['parent_id' => $assets->id, 'name' => 'الأصول المتداولة', 'type' => 'asset', 'balance_type' => 'debit']
        );
        Account::updateOrCreate(
            ['code' => '1101'],
            ['parent_id' => $currentAssets->id, 'name' => 'الصندوق (الكاش)', 'type' => 'asset', 'balance_type' => 'debit']
        );
        Account::updateOrCreate(
            ['code' => '1102'],
            ['parent_id' => $currentAssets->id, 'name' => 'البنك', 'type' => 'asset', 'balance_type' => 'debit']
        );
        Account::updateOrCreate(
            ['code' => '1103'],
            ['parent_id' => $currentAssets->id, 'name' => 'الذمم المدينة (العملاء)', 'type' => 'asset', 'balance_type' => 'debit']
        );
        Account::updateOrCreate(
            ['code' => '1104'],
            ['parent_id' => $currentAssets->id, 'name' => 'المخزون', 'type' => 'asset', 'balance_type' => 'debit']
        );

        // Current Liabilities
        $currentLiabilities = Account::updateOrCreate(
            ['code' => '21'],
            ['parent_id' => $liabilities->id, 'name' => 'الخصوم المتداولة', 'type' => 'liability', 'balance_type' => 'credit']
        );
        Account::updateOrCreate(
            ['code' => '2101'],
            ['parent_id' => $currentLiabilities->id, 'name' => 'الذمم الدائنة (الموردين)', 'type' => 'liability', 'balance_type' => 'credit']
        );
        
        // Sales
        Account::updateOrCreate(
            ['code' => '4101'],
            ['parent_id' => $revenue->id, 'name' => 'مبيعات البضاعة', 'type' => 'revenue', 'balance_type' => 'credit']
        );
        
        // COGS and Expenses
        Account::updateOrCreate(
            ['code' => '5101'],
            ['parent_id' => $expenses->id, 'name' => 'تكلفة البضاعة المباعة', 'type' => 'expense', 'balance_type' => 'debit']
        );
        Account::updateOrCreate(
            ['code' => '5201'],
            ['parent_id' => $expenses->id, 'name' => 'مصاريف رواتب وأجور', 'type' => 'expense', 'balance_type' => 'debit']
        );
    }
}
