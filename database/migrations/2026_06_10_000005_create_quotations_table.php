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
        if (!Schema::hasTable('quotations')) {
            Schema::create('quotations', function (Blueprint $table) {
                $table->id();
                $table->string('quotation_number')->unique();
                $table->foreignId('party_id')->constrained('parties')->onDelete('restrict');
                $table->foreignId('store_id')->nullable()->constrained('stores')->nullOnDelete();
                $table->date('date');
                $table->date('expiry_date')->nullable();
                $table->string('status')->default('draft'); // draft, sent, accepted, converted, rejected
                $table->decimal('subtotal', 15, 2)->default(0);
                $table->decimal('discount', 15, 2)->default(0);
                $table->decimal('tax_amount', 15, 2)->default(0);
                $table->decimal('total_amount', 15, 2)->default(0);
                $table->text('notes')->nullable();
                $table->foreignId('converted_invoice_id')->nullable()->constrained('invoices')->nullOnDelete();
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('quotation_lines')) {
            Schema::create('quotation_lines', function (Blueprint $table) {
                $table->id();
                $table->foreignId('quotation_id')->constrained('quotations')->onDelete('cascade');
                $table->foreignId('item_id')->constrained('items')->onDelete('restrict');
                $table->decimal('quantity', 15, 2);
                $table->decimal('unit_price', 15, 2);
                $table->decimal('total_price', 15, 2);
                $table->string('notes')->nullable();
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('quotation_lines');
        Schema::dropIfExists('quotations');
    }
};
