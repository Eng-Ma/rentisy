<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;
use App\Models\Item;
use App\Models\Store;
use App\Models\StoreItem;
use App\Models\Party;
use App\Models\User;
use App\Models\Account;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Invoice;
use App\Models\InvoiceLine;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class StorefrontSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Ensure Default Admin User has role 'admin'
        User::updateOrCreate(
            ['email' => 'admin@admin.com'],
            [
                'name' => 'مدير النظام المحاسبي',
                'password' => Hash::make('password'),
                'role' => 'admin',
            ]
        );

        // 2. Ensure Default Warehouse
        $store = Store::firstOrCreate(
            ['id' => 1],
            ['name' => 'المستودع المركزي الرئيسي (غزة)', 'location' => 'غزة - المنطقة الصناعية', 'is_active' => true]
        );

        // 3. Ensure Categories
        $categoriesData = [
            ['name' => 'أجهزة لابتوب وحواسيب', 'description' => 'حواسيب محمولة ومكتبية متطورة للأعمال، التصميم، والبرمجة مع كفالة رسمية'],
            ['name' => 'هواتف ذكية وأجهزة لوحية', 'description' => 'أحدث هواتف Apple و Samsung و Xiaomi الأصلية مع ضمان الوكيل'],
            ['name' => 'شاشات وتلفزيونات ذكية', 'description' => 'شاشات 4K فائقة الوضوح ومعدلات تحديث عالية للمصممين والألعاب'],
            ['name' => 'سماعات وصوتيات احترافية', 'description' => 'سماعات رأس لاسلكية بنقاء عالي وعزل ضوضاء نشط'],
            ['name' => 'إكسسوارات وملحقات تقنية', 'description' => 'شواحن GaN السريعة، لوحات مفاتيح ميكانيكية، وماوسات احترافية'],
            ['name' => 'أجهزة ذكية ومنزلية', 'description' => 'حلول المنزل الذكي وكاميرات المراقبة والأجهزة المتصلة'],
        ];

        $categories = [];
        foreach ($categoriesData as $c) {
            $categories[$c['name']] = Category::updateOrCreate(
                ['name' => $c['name']],
                ['description' => $c['description'], 'is_active' => true]
            );
        }

        // 4. Seed Real Market Products (with realistic Palestinian market prices in ILS ₪)
        $itemsData = [
            [
                'name' => 'Apple MacBook Pro 16" (M3 Max / 36GB / 1TB SSD)',
                'category' => 'أجهزة لابتوب وحواسيب',
                'barcode' => '195949012001',
                'image' => 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&auto=format&fit=crop&q=80',
                'description' => 'شاشة Liquid Retina XDR مبهرة، معالج M3 Max مع 14 نواة CPU و 30 نواة GPU، بطارية تدوم حتى 22 ساعة، منافذ Thunderbolt 4 و MagSafe 3.',
                'sales_price' => 12500,
                'discount_price' => 11850,
                'is_featured' => true,
                'is_deal' => true,
                'rating' => 5.0,
                'reviews_count' => 48,
                'stock' => 12,
            ],
            [
                'name' => 'Dell XPS 15 9530 Touch (Core i9-13900H / RTX 4070 / 32GB)',
                'category' => 'أجهزة لابتوب وحواسيب',
                'barcode' => '195949012002',
                'image' => 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=800&auto=format&fit=crop&q=80',
                'description' => 'شاشة 3.5K OLED لمسية بدقة ألوان DCI-P3 100%، هيكل ألومنيوم مع مسند معصم من ألياف الكربون، وقوة معالجة خارقة.',
                'sales_price' => 8900,
                'discount_price' => 8400,
                'is_featured' => true,
                'is_deal' => false,
                'rating' => 4.8,
                'reviews_count' => 31,
                'stock' => 18,
            ],
            [
                'name' => 'Lenovo ThinkPad X1 Carbon Gen 11 (Core i7 / 16GB / 512GB)',
                'category' => 'أجهزة لابتوب وحواسيب',
                'barcode' => '195949012003',
                'image' => 'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=800&auto=format&fit=crop&q=80',
                'description' => 'لابتوب الأعمال الأول فائق الخفة والمتانة، كيبورد مريح ومقاوم للسوائل، قارئ بصمة وأمان معتمد للأعمال والمحاسبة.',
                'sales_price' => 6700,
                'discount_price' => 6200,
                'is_featured' => false,
                'is_deal' => true,
                'rating' => 4.9,
                'reviews_count' => 22,
                'stock' => 20,
            ],
            [
                'name' => 'iPhone 16 Pro Max 256GB Desert Titanium',
                'category' => 'هواتف ذكية وأجهزة لوحية',
                'barcode' => '195949012004',
                'image' => 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=800&auto=format&fit=crop&q=80',
                'description' => 'هيكل تيتانيوم صلب ومصقول، زر التحكم بالكاميرا الجديد، معالج A18 Pro فائق السرعة، تقريب بصري 5x وزجاج درع السيراميك.',
                'sales_price' => 5400,
                'discount_price' => 4950,
                'is_featured' => true,
                'is_deal' => true,
                'rating' => 4.9,
                'reviews_count' => 112,
                'stock' => 35,
            ],
            [
                'name' => 'Samsung Galaxy S24 Ultra 512GB Titanium Gray',
                'category' => 'هواتف ذكية وأجهزة لوحية',
                'barcode' => '195949012005',
                'image' => 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=800&auto=format&fit=crop&q=80',
                'description' => 'ميزات Galaxy AI للترجمة الفورية، قلم S-Pen بدقة فائقة، كاميرا 200MP مع معالج Snapdragon 8 Gen 3 المخصص.',
                'sales_price' => 4800,
                'discount_price' => 4500,
                'is_featured' => true,
                'is_deal' => false,
                'rating' => 4.8,
                'reviews_count' => 76,
                'stock' => 28,
            ],
            [
                'name' => 'iPad Pro 13-inch M4 Ultra Retina XDR 256GB',
                'category' => 'هواتف ذكية وأجهزة لوحية',
                'barcode' => '195949012006',
                'image' => 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=800&auto=format&fit=crop&q=80',
                'description' => 'أنحف جهاز من Apple بسماكة 5.1 مم، شاشة OLED ترادفية مذهلة، معالج M4 الجبار، متوافق مع Apple Pencil Pro.',
                'sales_price' => 5200,
                'discount_price' => 4850,
                'is_featured' => true,
                'is_deal' => true,
                'rating' => 4.9,
                'reviews_count' => 39,
                'stock' => 15,
            ],
            [
                'name' => 'LG UltraFine 32UN880-B 4K Ergo Monitor 32"',
                'category' => 'شاشات وتلفزيونات ذكية',
                'barcode' => '195949012007',
                'image' => 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=800&auto=format&fit=crop&q=80',
                'description' => 'شاشة 4K IPS مع ذراع مريح يثبت على المكتب قابل للدوران بالكامل، منفذ USB Type-C للشحن ونقل الصورة 60W.',
                'sales_price' => 2850,
                'discount_price' => 2490,
                'is_featured' => false,
                'is_deal' => true,
                'rating' => 4.8,
                'reviews_count' => 25,
                'stock' => 14,
            ],
            [
                'name' => 'Sony WH-1000XM5 Wireless Noise Cancelling Headphones',
                'category' => 'سماعات وصوتيات احترافية',
                'barcode' => '195949012008',
                'image' => 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&auto=format&fit=crop&q=80',
                'description' => 'نظام عزل الضوضاء التكيفي الحائز على جوائز عالمية، 8 ميكروفونات للمكالمات الصوتية النقية، دعم الصوت عالي الدقة Hi-Res و LDAC.',
                'sales_price' => 1450,
                'discount_price' => 1190,
                'is_featured' => true,
                'is_deal' => true,
                'rating' => 4.9,
                'reviews_count' => 84,
                'stock' => 40,
            ],
            [
                'name' => 'Apple AirPods Pro (2nd Gen / USB-C MagSafe)',
                'category' => 'سماعات وصوتيات احترافية',
                'barcode' => '195949012009',
                'image' => 'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=800&auto=format&fit=crop&q=80',
                'description' => 'معالج H2 الصوتي المتطور، ميزة الصوت المكاني المخصص، إلغاء ضوضاء نشط مضاعف، ومقاومة الماء والغبار بمعيار IP54.',
                'sales_price' => 950,
                'discount_price' => 840,
                'is_featured' => false,
                'is_deal' => true,
                'rating' => 4.9,
                'reviews_count' => 95,
                'stock' => 60,
            ],
            [
                'name' => 'Apple Watch Ultra 2 GPS + Cellular 49mm Titanium',
                'category' => 'إكسسوارات وملحقات تقنية',
                'barcode' => '195949012010',
                'image' => 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&auto=format&fit=crop&q=80',
                'description' => 'شاشة بسطوع 3000 شمعة تحت أشعة الشمس، مقاومة للمياه حتى عمق 100 متر، معالج S9 SiP فائق السرعة وبطارية تدوم 72 ساعة.',
                'sales_price' => 3200,
                'discount_price' => 2950,
                'is_featured' => true,
                'is_deal' => false,
                'rating' => 5.0,
                'reviews_count' => 33,
                'stock' => 16,
            ],
            [
                'name' => 'Logitech MX Master 3S + MX Keys Combo',
                'category' => 'إكسسوارات وملحقات تقنية',
                'barcode' => '195949012011',
                'image' => 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800&auto=format&fit=crop&q=80',
                'description' => 'المجموعة الإنتاجية المفضلة للمحاسبين والمبرمجين، حساس بدقة 8000 DPI يعمل على كافة الأسطح حتى الزجاج، ونقر هادئ 90%.',
                'sales_price' => 850,
                'discount_price' => 690,
                'is_featured' => false,
                'is_deal' => true,
                'rating' => 4.9,
                'reviews_count' => 57,
                'stock' => 45,
            ],
            [
                'name' => 'Anker Prime 20,000mAh Power Bank (200W Output)',
                'category' => 'إكسسوارات وملحقات تقنية',
                'barcode' => '195949012012',
                'image' => 'https://images.unsplash.com/photo-1609091839311-d5368f9bc14a?w=800&auto=format&fit=crop&q=80',
                'description' => 'شاحن متنقل بقوة 200W قادر على شحن جهازي لابتوب بسرعة قصوى بوقت واحد، شاشة رقمية ذكية توضح مدة الشحن وطاقة كل منفذ.',
                'sales_price' => 480,
                'discount_price' => 390,
                'is_featured' => false,
                'is_deal' => true,
                'rating' => 4.8,
                'reviews_count' => 42,
                'stock' => 30,
            ],
        ];

        foreach ($itemsData as $data) {
            $cat = $categories[$data['category']] ?? null;

            $item = Item::updateOrCreate(
                ['barcode' => $data['barcode']],
                [
                    'category_id' => $cat?->id,
                    'name' => $data['name'],
                    'image' => $data['image'],
                    'description' => $data['description'],
                    'unit' => 'قطعة',
                    'purchase_price' => round($data['sales_price'] * 0.72, 2),
                    'sales_price' => $data['sales_price'],
                    'discount_price' => $data['discount_price'],
                    'is_active' => true,
                    'is_featured' => $data['is_featured'],
                    'is_deal' => $data['is_deal'],
                    'rating' => $data['rating'],
                    'reviews_count' => $data['reviews_count'],
                ]
            );

            // Store stock
            StoreItem::updateOrCreate(
                ['store_id' => $store->id, 'item_id' => $item->id],
                ['quantity' => $data['stock']]
            );
        }

        // 5. Create Realistic Customer Users with Linked Accounting Parties
        $arAccount = Account::where('code', '1103')->orWhere('name', 'like', '%عملاء%')->first();

        // Customer 1: المهندس محمود
        $party1 = Party::firstOrCreate(
            ['name' => 'م. محمود علي (عميل متجر)'],
            [
                'type' => 'customer',
                'phone' => '0599123456',
                'address' => 'غزة - شارع الرمال الرئيسي، عمارة الأمل',
                'account_id' => $arAccount?->id,
            ]
        );

        $customer1 = User::updateOrCreate(
            ['email' => 'customer@store.com'],
            [
                'name' => 'م. محمود علي',
                'password' => Hash::make('password'),
                'role' => 'customer',
                'phone' => '0599123456',
                'address' => 'شارع الرمال الرئيسي، عمارة الأمل، طابق 3',
                'city' => 'غزة',
                'google_id' => 'google_demo_109283746',
                'facebook_id' => 'facebook_demo_982374615',
                'avatar' => 'https://api.dicebear.com/7.x/bottts/svg?seed=Mahmoud',
                'party_id' => $party1->id,
            ]
        );

        // Customer 2: د. سارة أحمد
        $party2 = Party::firstOrCreate(
            ['name' => 'د. سارة أحمد (عميل متجر)'],
            [
                'type' => 'customer',
                'phone' => '0599876543',
                'address' => 'رام الله - شارع الإرسال',
                'account_id' => $arAccount?->id,
            ]
        );

        $customer2 = User::updateOrCreate(
            ['email' => 'sara@store.com'],
            [
                'name' => 'د. سارة أحمد',
                'password' => Hash::make('password'),
                'role' => 'customer',
                'phone' => '0599876543',
                'address' => 'شارع الإرسال، مقابل برج فلسطين',
                'city' => 'رام الله',
                'google_id' => 'google_demo_55667788',
                'party_id' => $party2->id,
            ]
        );

        // Customer 3: أ. خالد النجار
        $party3 = Party::firstOrCreate(
            ['name' => 'أ. خالد النجار (عميل متجر)'],
            [
                'type' => 'customer',
                'phone' => '0569112233',
                'address' => 'خان يونس - شارع جلال',
                'account_id' => $arAccount?->id,
            ]
        );

        $customer3 = User::updateOrCreate(
            ['email' => 'khaled@store.com'],
            [
                'name' => 'أ. خالد النجار',
                'password' => Hash::make('password'),
                'role' => 'customer',
                'phone' => '0569112233',
                'address' => 'شارع جلال، مجمع النجار التجاري',
                'city' => 'خان يونس',
                'party_id' => $party3->id,
            ]
        );

        // 6. Seed Realistic Orders across multiple statuses (for Admin Panel & MCP AI Analysis)
        $ordersSample = [
            [
                'order_number' => 'ORD-20260830-101',
                'user' => $customer1,
                'party' => $party1,
                'item_barcode' => '195949012008', // Sony Headphones
                'qty' => 1,
                'status' => 'delivered',
                'payment_method' => 'cod',
                'payment_status' => 'paid',
                'days_ago' => 5,
                'notes' => 'تسليم باليد في مقر الشركة - تم السداد',
            ],
            [
                'order_number' => 'ORD-20260830-102',
                'user' => $customer2,
                'party' => $party2,
                'item_barcode' => '195949012004', // iPhone 16 Pro Max
                'qty' => 1,
                'status' => 'shipped',
                'payment_method' => 'card',
                'payment_status' => 'paid',
                'days_ago' => 2,
                'notes' => 'شحن سريع عبر شركة التوصيل مع رقم التتبع #PL-8921',
            ],
            [
                'order_number' => 'ORD-20260830-103',
                'user' => $customer3,
                'party' => $party3,
                'item_barcode' => '195949012011', // Logitech Combo
                'qty' => 2,
                'status' => 'processing',
                'payment_method' => 'cod',
                'payment_status' => 'unpaid',
                'days_ago' => 1,
                'notes' => 'جاري تجهيز الشحنة من المستودع الرئيسي',
            ],
            [
                'order_number' => 'ORD-20260830-104',
                'user' => $customer1,
                'party' => $party1,
                'item_barcode' => '195949012009', // AirPods Pro
                'qty' => 1,
                'status' => 'pending',
                'payment_method' => 'cod',
                'payment_status' => 'unpaid',
                'days_ago' => 0,
                'notes' => 'طلب جديد بانتظار التأكيد الهاتفي مع الزبون',
            ],
            [
                'order_number' => 'ORD-20260830-105',
                'user' => $customer2,
                'party' => $party2,
                'item_barcode' => '195949012001', // MacBook Pro M3
                'qty' => 1,
                'status' => 'processing',
                'payment_method' => 'bank_transfer',
                'payment_status' => 'paid',
                'days_ago' => 1,
                'notes' => 'تم استلام إشعار الحوالة البنكية بنك فلسطين #TRX-998822',
            ],
        ];

        foreach ($ordersSample as $ordData) {
            $item = Item::where('barcode', $ordData['item_barcode'])->first();
            if (!$item) continue;

            $totalPrice = $item->effective_price * $ordData['qty'];
            $shipping = $totalPrice > 200 ? 0 : 20;
            $orderTotal = $totalPrice + $shipping;

            $existingOrder = Order::where('order_number', $ordData['order_number'])->first();
            if (!$existingOrder) {
                // Accounting sales invoice
                $invoice = Invoice::create([
                    'type' => 'sale',
                    'date' => now()->subDays($ordData['days_ago'])->toDateString(),
                    'party_id' => $ordData['party']->id,
                    'store_id' => $store->id,
                    'notes' => "فاتورة مبيعات طلب متجر #{$ordData['order_number']} - {$ordData['notes']}",
                ]);

                InvoiceLine::create([
                    'invoice_id' => $invoice->id,
                    'item_id' => $item->id,
                    'quantity' => $ordData['qty'],
                    'unit_price' => $item->effective_price,
                ]);

                // Store Order
                $order = Order::create([
                    'order_number' => $ordData['order_number'],
                    'user_id' => $ordData['user']->id,
                    'party_id' => $ordData['party']->id,
                    'invoice_id' => $invoice->id,
                    'status' => $ordData['status'],
                    'subtotal' => $totalPrice,
                    'discount_amount' => 0,
                    'shipping_fee' => $shipping,
                    'total_amount' => $orderTotal,
                    'payment_method' => $ordData['payment_method'],
                    'payment_status' => $ordData['payment_status'],
                    'shipping_name' => $ordData['user']->name,
                    'shipping_phone' => $ordData['user']->phone ?? '0599000000',
                    'shipping_address' => $ordData['user']->address ?? 'غزة - شارع النصر',
                    'shipping_city' => $ordData['user']->city ?? 'غزة',
                    'notes' => $ordData['notes'],
                    'created_at' => now()->subDays($ordData['days_ago']),
                ]);

                OrderItem::create([
                    'order_id' => $order->id,
                    'item_id' => $item->id,
                    'item_name' => $item->name,
                    'quantity' => $ordData['qty'],
                    'unit_price' => $item->effective_price,
                    'total_price' => $totalPrice,
                ]);
            }
        }
    }
}
