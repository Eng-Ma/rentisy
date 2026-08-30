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
        // 1. Create delivery_zones table
        if (!Schema::hasTable('delivery_zones')) {
            Schema::create('delivery_zones', function (Blueprint $table) {
                $table->id();
                $table->string('name');
                $table->string('city');
                $table->decimal('delivery_fee', 10, 2)->default(15.00);
                $table->string('estimated_time')->default('خلال 24-48 ساعة');
                $table->boolean('is_active')->default(true);
                $table->boolean('is_approved')->default(true);
                $table->foreignId('suggested_by_user_id')->nullable()->constrained('users')->nullOnDelete();
                $table->string('status')->default('approved'); // approved, pending, rejected
                $table->text('admin_notes')->nullable();
                $table->timestamps();
            });
        }

        // 2. Add delivery and payment proof columns to orders
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'delivery_type')) {
                $table->string('delivery_type')->default('delivery')->after('payment_status'); // delivery, pickup
            }
            if (!Schema::hasColumn('orders', 'delivery_zone_id')) {
                $table->foreignId('delivery_zone_id')->nullable()->after('delivery_type')->constrained('delivery_zones')->nullOnDelete();
            }
            if (!Schema::hasColumn('orders', 'payment_receipt_url')) {
                $table->string('payment_receipt_url')->nullable()->after('payment_method');
            }
            if (!Schema::hasColumn('orders', 'is_payment_verified')) {
                $table->boolean('is_payment_verified')->default(false)->after('payment_receipt_url');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['delivery_zone_id']);
            $table->dropColumn(['delivery_type', 'delivery_zone_id', 'payment_receipt_url', 'is_payment_verified']);
        });

        Schema::dropIfExists('delivery_zones');
    }
};
