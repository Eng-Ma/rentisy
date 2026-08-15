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
        if (!Schema::hasTable('checks')) {
            Schema::create('checks', function (Blueprint $table) {
                $table->id();
                $table->string('check_number');
                $table->string('type'); // received (شيك وارد), issued (شيك صادر)
                $table->string('bank_name');
                $table->string('branch')->nullable();
                $table->string('drawer_name')->nullable(); // الساحب
                $table->string('beneficiary_name')->nullable(); // المستفيد
                $table->date('issue_date')->nullable();
                $table->date('due_date'); // تاريخ الاستحقاق
                $table->decimal('amount', 15, 2);
                $table->foreignId('currency_id')->constrained('currencies')->onDelete('restrict');
                $table->string('status')->default('under_collection'); // under_collection (برسم التحصيل), collected (محصل), endorsed (مجير), bounced (مرتجع), cancelled (ملغي)
                $table->foreignId('party_id')->nullable()->constrained('parties')->nullOnDelete();
                $table->foreignId('endorsed_party_id')->nullable()->constrained('parties')->nullOnDelete(); // في حال التجيير لمورد
                $table->foreignId('voucher_id')->nullable()->constrained('vouchers')->nullOnDelete();
                $table->foreignId('journal_entry_id')->nullable()->constrained('journal_entries')->nullOnDelete();
                $table->date('collection_date')->nullable();
                $table->text('notes')->nullable();
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('checks');
    }
};
