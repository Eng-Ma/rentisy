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
        if (!Schema::hasTable('stock_transfers')) {
            Schema::create('stock_transfers', function (Blueprint $table) {
                $table->id();
                $table->string('transfer_number')->unique();
                $table->string('type')->default('transfer'); // transfer (مناقلة), stock_in (إدخال), stock_out (إخراج), adjustment (تسوية)
                $table->foreignId('from_store_id')->nullable()->constrained('stores')->nullOnDelete();
                $table->foreignId('to_store_id')->nullable()->constrained('stores')->nullOnDelete();
                $table->date('date');
                $table->text('notes')->nullable();
                $table->string('status')->default('completed'); // completed, pending
                $table->foreignId('journal_entry_id')->nullable()->constrained('journal_entries')->nullOnDelete();
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('stock_transfer_lines')) {
            Schema::create('stock_transfer_lines', function (Blueprint $table) {
                $table->id();
                $table->foreignId('stock_transfer_id')->constrained('stock_transfers')->onDelete('cascade');
                $table->foreignId('item_id')->constrained('items')->onDelete('restrict');
                $table->decimal('quantity', 15, 2);
                $table->decimal('unit_cost', 15, 2)->default(0);
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
        Schema::dropIfExists('stock_transfer_lines');
        Schema::dropIfExists('stock_transfers');
    }
};
