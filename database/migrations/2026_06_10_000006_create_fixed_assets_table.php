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
        if (!Schema::hasTable('fixed_assets')) {
            Schema::create('fixed_assets', function (Blueprint $table) {
                $table->id();
                $table->string('code')->unique();
                $table->string('name');
                $table->date('purchase_date');
                $table->decimal('purchase_cost', 15, 2);
                $table->decimal('salvage_value', 15, 2)->default(0);
                $table->decimal('useful_life_years', 5, 2)->default(5);
                $table->decimal('depreciation_rate', 5, 2)->default(20);
                $table->string('depreciation_method')->default('straight_line'); // straight_line (القسط الثابت)
                $table->foreignId('asset_account_id')->nullable()->constrained('accounts')->nullOnDelete();
                $table->foreignId('depreciation_expense_account_id')->nullable()->constrained('accounts')->nullOnDelete();
                $table->foreignId('accumulated_depreciation_account_id')->nullable()->constrained('accounts')->nullOnDelete();
                $table->foreignId('cost_center_id')->nullable()->constrained('cost_centers')->nullOnDelete();
                $table->decimal('total_depreciated', 15, 2)->default(0);
                $table->decimal('current_book_value', 15, 2);
                $table->boolean('is_active')->default(true);
                $table->text('notes')->nullable();
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('asset_depreciations')) {
            Schema::create('asset_depreciations', function (Blueprint $table) {
                $table->id();
                $table->foreignId('fixed_asset_id')->constrained('fixed_assets')->onDelete('cascade');
                $table->date('date');
                $table->decimal('amount', 15, 2);
                $table->foreignId('journal_entry_id')->nullable()->constrained('journal_entries')->nullOnDelete();
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
        Schema::dropIfExists('asset_depreciations');
        Schema::dropIfExists('fixed_assets');
    }
};
