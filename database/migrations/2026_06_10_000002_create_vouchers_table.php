<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasTable('vouchers')) {
            Schema::create('vouchers', function (Blueprint $table) {
                $table->id();
                $table->string('voucher_number')->unique();
                $table->string('type'); // receipt (سند قبض), payment (سند صرف)
                $table->string('payment_method')->default('cash'); // cash (نقدي), bank (بنكي), check (شيك)
                $table->date('date');
                $table->foreignId('account_id')->constrained('accounts')->onDelete('restrict'); // حساب الصندوق / البنك
                $table->foreignId('party_id')->nullable()->constrained('parties')->nullOnDelete(); // العميل / المورد
                $table->foreignId('target_account_id')->nullable()->constrained('accounts')->nullOnDelete(); // الحساب المقابل (مصروف/إيراد/حساب آخر)
                $table->foreignId('cost_center_id')->nullable()->constrained('cost_centers')->nullOnDelete();
                $table->foreignId('currency_id')->constrained('currencies')->onDelete('restrict');
                $table->decimal('exchange_rate', 15, 4)->default(1.0);
                $table->decimal('amount', 15, 2);
                $table->string('check_number')->nullable();
                $table->date('check_date')->nullable();
                $table->string('bank_name')->nullable();
                $table->text('notes')->nullable();
                $table->foreignId('journal_entry_id')->nullable()->constrained('journal_entries')->nullOnDelete();
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vouchers');
    }
};
