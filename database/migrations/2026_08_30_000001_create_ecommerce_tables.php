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
        // 1. Add storefront & social auth fields to users table
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'role')) {
                $table->string('role')->default('customer')->after('id'); // 'admin', 'customer'
            }
            if (!Schema::hasColumn('users', 'phone')) {
                $table->string('phone')->nullable()->after('email');
            }
            if (!Schema::hasColumn('users', 'address')) {
                $table->text('address')->nullable()->after('phone');
            }
            if (!Schema::hasColumn('users', 'city')) {
                $table->string('city')->nullable()->after('address');
            }
            if (!Schema::hasColumn('users', 'google_id')) {
                $table->string('google_id')->nullable()->index()->after('city');
            }
            if (!Schema::hasColumn('users', 'facebook_id')) {
                $table->string('facebook_id')->nullable()->index()->after('google_id');
            }
            if (!Schema::hasColumn('users', 'avatar')) {
                $table->string('avatar')->nullable()->after('facebook_id');
            }
            if (!Schema::hasColumn('users', 'party_id')) {
                $table->foreignId('party_id')->nullable()->constrained('parties')->nullOnDelete()->after('avatar');
            }
        });

        // 2. Add storefront fields to items table
        Schema::table('items', function (Blueprint $table) {
            if (!Schema::hasColumn('items', 'image')) {
                $table->string('image')->nullable()->after('name');
            }
            if (!Schema::hasColumn('items', 'is_featured')) {
                $table->boolean('is_featured')->default(false)->after('is_active');
            }
            if (!Schema::hasColumn('items', 'is_deal')) {
                $table->boolean('is_deal')->default(false)->after('is_featured');
            }
            if (!Schema::hasColumn('items', 'discount_price')) {
                $table->decimal('discount_price', 15, 4)->nullable()->after('sales_price');
            }
            if (!Schema::hasColumn('items', 'rating')) {
                $table->decimal('rating', 3, 2)->default(5.0)->after('discount_price');
            }
            if (!Schema::hasColumn('items', 'reviews_count')) {
                $table->integer('reviews_count')->default(0)->after('rating');
            }
            if (!Schema::hasColumn('items', 'tags')) {
                $table->string('tags')->nullable()->after('reviews_count');
            }
        });

        // 3. Create cart_items table
        if (!Schema::hasTable('cart_items')) {
            Schema::create('cart_items', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->nullable()->constrained('users')->cascadeOnDelete();
                $table->string('session_id')->nullable()->index();
                $table->foreignId('item_id')->constrained('items')->cascadeOnDelete();
                $table->integer('quantity')->default(1);
                $table->timestamps();
            });
        }

        // 4. Create wishlist_items table
        if (!Schema::hasTable('wishlist_items')) {
            Schema::create('wishlist_items', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
                $table->foreignId('item_id')->constrained('items')->cascadeOnDelete();
                $table->timestamps();
                $table->unique(['user_id', 'item_id']);
            });
        }

        // 5. Create orders table
        if (!Schema::hasTable('orders')) {
            Schema::create('orders', function (Blueprint $table) {
                $table->id();
                $table->string('order_number')->unique();
                $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
                $table->foreignId('party_id')->nullable()->constrained('parties')->nullOnDelete();
                $table->foreignId('invoice_id')->nullable()->constrained('invoices')->nullOnDelete();
                $table->enum('status', ['pending', 'processing', 'shipped', 'delivered', 'cancelled'])->default('pending');
                $table->decimal('subtotal', 15, 4)->default(0);
                $table->decimal('discount_amount', 15, 4)->default(0);
                $table->decimal('shipping_fee', 15, 4)->default(0);
                $table->decimal('total_amount', 15, 4)->default(0);
                $table->string('payment_method')->default('cod'); // cod, card, bank_transfer
                $table->enum('payment_status', ['unpaid', 'paid', 'refunded'])->default('unpaid');
                $table->string('shipping_name');
                $table->string('shipping_phone');
                $table->text('shipping_address');
                $table->string('shipping_city')->nullable();
                $table->text('notes')->nullable();
                $table->timestamps();
            });
        }

        // 6. Create order_items table
        if (!Schema::hasTable('order_items')) {
            Schema::create('order_items', function (Blueprint $table) {
                $table->id();
                $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
                $table->foreignId('item_id')->nullable()->constrained('items')->nullOnDelete();
                $table->string('item_name');
                $table->integer('quantity')->default(1);
                $table->decimal('unit_price', 15, 4)->default(0);
                $table->decimal('total_price', 15, 4)->default(0);
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('wishlist_items');
        Schema::dropIfExists('cart_items');

        Schema::table('items', function (Blueprint $table) {
            $table->dropColumn([
                'image', 'is_featured', 'is_deal', 'discount_price', 'rating', 'reviews_count', 'tags'
            ]);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['party_id']);
            $table->dropColumn([
                'role', 'phone', 'address', 'city', 'google_id', 'facebook_id', 'avatar', 'party_id'
            ]);
        });
    }
};
