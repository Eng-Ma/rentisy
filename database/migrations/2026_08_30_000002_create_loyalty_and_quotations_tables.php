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
        // 1. Add loyalty fields to users
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'points_balance')) {
                $table->integer('points_balance')->default(150)->after('party_id');
            }
            if (!Schema::hasColumn('users', 'referral_code')) {
                $table->string('referral_code')->nullable()->unique()->after('points_balance');
            }
            if (!Schema::hasColumn('users', 'tier')) {
                $table->string('tier')->default('silver')->after('referral_code'); // bronze, silver, gold, diamond
            }
        });

        // 2. Add points tracking to orders
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'points_earned')) {
                $table->integer('points_earned')->default(0)->after('discount_amount');
            }
            if (!Schema::hasColumn('orders', 'points_redeemed')) {
                $table->integer('points_redeemed')->default(0)->after('points_earned');
            }
            if (!Schema::hasColumn('orders', 'cashback_discount')) {
                $table->decimal('cashback_discount', 10, 2)->default(0)->after('points_redeemed');
            }
        });

        // 3. Create loyalty_transactions table
        if (!Schema::hasTable('loyalty_transactions')) {
            Schema::create('loyalty_transactions', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
                $table->integer('points');
                $table->string('type'); // earned, redeemed, referral_bonus, welcome_bonus
                $table->string('description');
                $table->foreignId('order_id')->nullable()->constrained('orders')->nullOnDelete();
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('loyalty_transactions');

        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['points_earned', 'points_redeemed', 'cashback_discount']);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['points_balance', 'referral_code', 'tier']);
        });
    }
};
