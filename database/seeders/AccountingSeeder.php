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
        Currency::create(['code' => 'ILS', 'name' => 'شيكل إسرائيلي', 'exchange_rate' => 1.0, 'is_default' => true]);
        Currency::create(['code' => 'USD', 'name' => 'دولار أمريكي', 'exchange_rate' => 3.75, 'is_default' => false]);
        Currency::create(['code' => 'JOD', 'name' => 'دينار أردني', 'exchange_rate' => 5.28, 'is_default' => false]);

        // 2. Chart of Accounts (Basic Tree)
        $assets = Account::create(['code' => '1', 'name' => 'الأصول', 'type' => 'asset', 'balance_type' => 'debit']);
        $liabilities = Account::create(['code' => '2', 'name' => 'الخصوم', 'type' => 'liability', 'balance_type' => 'credit']);
        $equity = Account::create(['code' => '3', 'name' => 'حقوق الملكية', 'type' => 'equity', 'balance_type' => 'credit']);
        $revenue = Account::create(['code' => '4', 'name' => 'الإيرادات', 'type' => 'revenue', 'balance_type' => 'credit']);
        $expenses = Account::create(['code' => '5', 'name' => 'المصروفات', 'type' => 'expense', 'balance_type' => 'debit']);

        // Current Assets
        $currentAssets = Account::create(['parent_id' => $assets->id, 'code' => '11', 'name' => 'الأصول المتداولة', 'type' => 'asset', 'balance_type' => 'debit']);
        Account::create(['parent_id' => $currentAssets->id, 'code' => '1101', 'name' => 'الصندوق (الكاش)', 'type' => 'asset', 'balance_type' => 'debit']);
        Account::create(['parent_id' => $currentAssets->id, 'code' => '1102', 'name' => 'البنك', 'type' => 'asset', 'balance_type' => 'debit']);
        Account::create(['parent_id' => $currentAssets->id, 'code' => '1103', 'name' => 'الذمم المدينة (العملاء)', 'type' => 'asset', 'balance_type' => 'debit']);
        Account::create(['parent_id' => $currentAssets->id, 'code' => '1104', 'name' => 'المخزون', 'type' => 'asset', 'balance_type' => 'debit']);

        // Current Liabilities
        $currentLiabilities = Account::create(['parent_id' => $liabilities->id, 'code' => '21', 'name' => 'الخصوم المتداولة', 'type' => 'liability', 'balance_type' => 'credit']);
        Account::create(['parent_id' => $currentLiabilities->id, 'code' => '2101', 'name' => 'الذمم الدائنة (الموردين)', 'type' => 'liability', 'balance_type' => 'credit']);
        
        // Sales
        Account::create(['parent_id' => $revenue->id, 'code' => '4101', 'name' => 'مبيعات البضاعة', 'type' => 'revenue', 'balance_type' => 'credit']);
        
        // COGS and Expenses
        Account::create(['parent_id' => $expenses->id, 'code' => '5101', 'name' => 'تكلفة البضاعة المباعة', 'type' => 'expense', 'balance_type' => 'debit']);
        Account::create(['parent_id' => $expenses->id, 'code' => '5201', 'name' => 'مصاريف رواتب وأجور', 'type' => 'expense', 'balance_type' => 'debit']);
    }
}
