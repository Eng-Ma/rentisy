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
        if (!Schema::hasTable('transfer_methods')) {
            Schema::create('transfer_methods', function (Blueprint $table) {
                $table->id();
                $table->string('name'); // e.g. "تحويل بنك فلسطين", "تحويل محفظة جوال باي", "تحويل لتاجر / محفظة"
                $table->string('account_name')->nullable(); // اسم صاحب الحساب / المستفيد
                $table->string('account_number')->nullable(); // رقم الحساب
                $table->string('iban')->nullable(); // الآيبان IBAN
                $table->string('phone')->nullable(); // رقم الجوال
                $table->string('logo_url')->nullable(); // شعار طريقة الدفع / البنك / المحفظة
                $table->text('instructions')->nullable(); // ملاحظات ومعلومات إضافية يضيفها الأدمن للزبون
                $table->boolean('is_active')->default(true);
                $table->integer('sort_order')->default(0);
                $table->timestamps();
            });
        } else {
            Schema::table('transfer_methods', function (Blueprint $table) {
                if (!Schema::hasColumn('transfer_methods', 'logo_url')) {
                    $table->string('logo_url')->nullable()->after('phone');
                }
            });
        }

        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'transfer_method_id')) {
                $table->foreignId('transfer_method_id')->nullable()->after('payment_method')->constrained('transfer_methods')->nullOnDelete();
            }
            if (!Schema::hasColumn('orders', 'transfer_method_name')) {
                $table->string('transfer_method_name')->nullable()->after('transfer_method_id');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['transfer_method_id']);
            $table->dropColumn(['transfer_method_id', 'transfer_method_name']);
        });

        Schema::dropIfExists('transfer_methods');
    }
};
