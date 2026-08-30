<?php

namespace Database\Seeders;

use App\Models\TransferMethod;
use Illuminate\Database\Seeder;

class TransferMethodSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $methods = [
            [
                'name' => 'تحويل بنك فلسطين (Bank of Palestine)',
                'account_name' => 'شركة رنتيسي للأنظمة والتجارة',
                'account_number' => '1892040',
                'iban' => 'PS66PALS000000000000001892040',
                'phone' => '0599123456',
                'logo_url' => 'https://images.unsplash.com/photo-1601597111158-2fceff292cdc?w=120&auto=format&fit=crop&q=80',
                'instructions' => 'الفرع الرئيسي - غزة (الرمال). يرجى التحويل من خلال تطبيق بنك فلسطين أو الصراف الآلي ثم إرفاق سكرين شوت إشعار التحويل لتأكيد الطلب فوراً.',
                'is_active' => true,
                'sort_order' => 1,
            ],
            [
                'name' => 'تحويل محفظة جوال باي (Jawwal Pay)',
                'account_name' => 'محفظة رنتيسي ستور المعتمدة',
                'account_number' => null,
                'iban' => null,
                'phone' => '0599123456',
                'logo_url' => 'https://images.unsplash.com/photo-1563013544-824ae1b704d3?w=120&auto=format&fit=crop&q=80',
                'instructions' => 'التحويل المباشر من تطبيق جوال باي إلى رقم المحفظة (0599123456). يرجى تصوير الشاشة بعد نجاح التحويل ورفعها هنا.',
                'is_active' => true,
                'sort_order' => 2,
            ],
            [
                'name' => 'تحويل لتاجر / محفظة بال باي (PalPay / Merchant)',
                'account_name' => 'رنتيسي للأنظمة والمحاسبة',
                'account_number' => 'MERCHANT-99882',
                'iban' => null,
                'phone' => '0599123456',
                'logo_url' => 'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?w=120&auto=format&fit=crop&q=80',
                'instructions' => 'كود التاجر المعتمد: 99882. يمكنك الدفع من أي نقطة بال باي أو تطبيق المحفظة الإلكترونية بإدخال كود التاجر ثم إرفاق إشعار السداد.',
                'is_active' => true,
                'sort_order' => 3,
            ],
            [
                'name' => 'البنك الإسلامي الفلسطيني (Palestine Islamic Bank)',
                'account_name' => 'شركة رنتيسي للحلول المحاسبية',
                'account_number' => '4401822',
                'iban' => 'PS44ISBK000000000000004401822',
                'phone' => '0599123456',
                'logo_url' => 'https://images.unsplash.com/photo-1541354329998-f4d9a9f9297f?w=120&auto=format&fit=crop&q=80',
                'instructions' => 'فرع النصر. يرجى التحويل للحساب عبر تطبيق إسلامي أونلاين ثم رفع إشعار التحويل البنكي.',
                'is_active' => true,
                'sort_order' => 4,
            ],
        ];

        foreach ($methods as $method) {
            TransferMethod::updateOrCreate(
                ['name' => $method['name']],
                $method
            );
        }
    }
}
