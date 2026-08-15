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
        if (!Schema::hasTable('cost_centers')) {
            Schema::create('cost_centers', function (Blueprint $table) {
                $table->id();
                $table->foreignId('parent_id')->nullable()->constrained('cost_centers')->onDelete('restrict');
                $table->string('code')->unique();
                $table->string('name');
                $table->boolean('is_active')->default(true);
                $table->text('description')->nullable();
                $table->timestamps();
            });
        }

        if (Schema::hasTable('journal_entry_lines') && !Schema::hasColumn('journal_entry_lines', 'cost_center_id')) {
            Schema::table('journal_entry_lines', function (Blueprint $table) {
                $table->foreignId('cost_center_id')->nullable()->after('account_id')->constrained('cost_centers')->nullOnDelete();
            });
        }

        if (Schema::hasTable('invoices') && !Schema::hasColumn('invoices', 'cost_center_id')) {
            Schema::table('invoices', function (Blueprint $table) {
                $table->foreignId('cost_center_id')->nullable()->after('store_id')->constrained('cost_centers')->nullOnDelete();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('invoices') && Schema::hasColumn('invoices', 'cost_center_id')) {
            Schema::table('invoices', function (Blueprint $table) {
                $table->dropConstrainedForeignId('cost_center_id');
            });
        }

        if (Schema::hasTable('journal_entry_lines') && Schema::hasColumn('journal_entry_lines', 'cost_center_id')) {
            Schema::table('journal_entry_lines', function (Blueprint $table) {
                $table->dropConstrainedForeignId('cost_center_id');
            });
        }

        Schema::dropIfExists('cost_centers');
    }
};
