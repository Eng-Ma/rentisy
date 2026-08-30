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
        // 1. Ensure Default Store
        $store = Store::firstOrCreate(
            ['id' => 1],
            ['name' => 'المستودع الرئيسي (غزة)', 'code' => 'MAIN-01', 'is_active' => true]
        );

        // 2. Ensure Categories
        $categoriesData = [
            ['name' => 'أجهزة لابتوب وحواسيب', 'description' => 'أحدث الحواسيب المحمولة والمكتبية للأعمال والألعاب'],
            ['name' => 'هواتف ذكية وأجهزة لوحية', 'description' => 'أحدث الهواتف الذكية مع ضمان رسمي وكفالة معتمدة'],
            ['name' => 'شاشات وتلفزيونات ذكية', 'description' => 'شاشات عرض بدقة 4K و 8K بأعلى معدلات التحديث'],
            ['name' => 'سماعات وصوتيات احترافية', 'description' => 'سماعات رأس لاسلكية ومكبرات صوت فائقة النقاء'],
            ['name' => 'إكسسوارات وملحقات', 'description' => 'شواحن سريعة، كوابل أصلية، وحقائب حماية'],
            ['name' => 'أجهزة منزلية ذكية', 'description' => 'حلول المنزل الذكي والأجهزة الكهربائية المتطورة'],
        ];

        $categories = [];
        foreach ($categoriesData as $c) {
            $categories[$c['name']] = Category::firstOrCreate(
                ['name' => $c['name']],
                ['description' => $c['description'], 'is_active' => true]
            );
        }

        // 3. Seed Products
        $itemsData = [
            [
                'name' => 'لابتوب MacBook Pro M3 Max 16-inch',
                'category' => 'أجهزة لابتوب وحواسيب',
                'barcode' => '690123450001',
                'image' => 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&auto=format&fit=crop&q=80',
                'description' => 'معالج M3 Max فائق القوة، ذاكرة موحدة 36GB، وسعة تخزين 1TB SSD مع شاشة Liquid Retina XDR مبهرة.',
                'sales_price' => 12500,
                'discount_price' => 11800,
                'is_featured' => true,
                'is_deal' => true,
                'rating' => 5.0,
                'reviews_count' => 34,
                'stock' => 15,
            ],
            [
                'name' => 'لابتوب Dell XPS 15 OLED Touch',
                'category' => 'أجهزة لابتوب وحواسيب',
                'barcode' => '690123450002',
                'image' => 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=800&auto=format&fit=crop&q=80',
                'description' => 'شاشة لمسية 3.5K OLED بدقة مذهلة، معالج Intel Core i9، كرت شاشة RTX 4070، وتصميم من ألياف الكربون.',
                'sales_price' => 8900,
                'discount_price' => 8400,
                'is_featured' => true,
                'is_deal' => false,
                'rating' => 4.8,
                'reviews_count' => 21,
                'stock' => 20,
            ],
            [
                'name' => 'هاتف iPhone 16 Pro Max 256GB تيتانيوم',
                'category' => 'هواتف ذكية وأجهزة لوحية',
                'barcode' => '690123450003',
                'image' => 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=800&auto=format&fit=crop&q=80',
                'description' => 'هيكل تيتانيوم صلب، معالج A18 Pro الثوري، نظام كاميرات احترافي بدقة 48MP، وبطارية تدوم طوال اليوم.',
                'sales_price' => 5400,
                'discount_price' => 4950,
                'is_featured' => true,
                'is_deal' => true,
                'rating' => 4.9,
                'reviews_count' => 89,
                'stock' => 40,
            ],
            [
                'name' => 'هاتف Samsung Galaxy S24 Ultra 512GB',
                'category' => 'هواتف ذكية وأجهزة لوحية',
                'barcode' => '690123450004',
                'image' => 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=800&auto=format&fit=crop&q=80',
                'description' => 'شاشة Dynamic AMOLED 2X مسطحة، قلم S-Pen مدمج، ميزات Galaxy AI الذكية، وكاميرا 200MP متفوقة.',
                'sales_price' => 4800,
                'discount_price' => null,
                'is_featured' => true,
                'is_deal' => false,
                'rating' => 4.7,
                'reviews_count' => 45,
                'stock' => 25,
            ],
            [
                'name' => 'شاشة LG UltraFine 4K Nano IPS 32-inch',
                'category' => 'شاشات وتلفزيونات ذكية',
                'barcode' => '690123450005',
                'image' => 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=800&auto=format&fit=crop&q=80',
                'description' => 'ألوان دقيقة بنسبة DCI-P3 98%، منفذ Thunderbolt 4 بقدرة شحن 96W، مثالية للمصممين والمحاسبين.',
                'sales_price' => 2800,
                'discount_price' => 2450,
                'is_featured' => false,
                'is_deal' => true,
                'rating' => 4.8,
                'reviews_count' => 19,
                'stock' => 18,
            ],
            [
                'name' => 'سماعات Sony WH-1000XM5 العازلة للضوضاء',
                'category' => 'سماعات وصوتيات احترافية',
                'barcode' => '690123450006',
                'image' => 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&auto=format&fit=crop&q=80',
                'description' => 'أفضل نظام إلغاء ضوضاء نشط في العالم مع معالجين، ميكروفونات متطورة للمكالمات، وبطارية 30 ساعة.',
                'sales_price' => 1450,
                'discount_price' => 1190,
                'is_featured' => true,
                'is_deal' => true,
                'rating' => 4.9,
                'reviews_count' => 62,
                'stock' => 30,
            ],
            [
                'name' => 'سماعات Apple AirPods Pro (الجيل الثاني Type-C)',
                'category' => 'سماعات وصوتيات احترافية',
                'barcode' => '690123450007',
                'image' => 'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=800&auto=format&fit=crop&q=80',
                'description' => 'معالج H2، شفافية صوتية تكيفية، علبة شحن MagSafe بمنفذ USB-C ومكبر صوت لتحديد الموقع.',
                'sales_price' => 950,
                'discount_price' => 850,
                'is_featured' => false,
                'is_deal' => true,
                'rating' => 4.8,
                'reviews_count' => 54,
                'stock' => 50,
            ],
            [
                'name' => 'ساعة Apple Watch Ultra 2 تيتانيوم',
                'category' => 'إكسسوارات وملحقات',
                'barcode' => '690123450008',
                'image' => 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&auto=format&fit=crop&q=80',
                'description' => 'أقوى ساعة ذكية للمغامرات والرياضات المائية، شاشة 3000 nits ساطعة، ونظام تحديد مواقع ثنائي التردد.',
                'sales_price' => 3200,
                'discount_price' => 2950,
                'is_featured' => true,
                'is_deal' => false,
                'rating' => 5.0,
                'reviews_count' => 27,
                'stock' => 12,
            ],
            [
                'name' => 'لوحة مفاتيح وماوس Logitech MX Master 3S Bundle',
                'category' => 'إكسسوارات وملحقات',
                'barcode' => '690123450009',
                'image' => 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800&auto=format&fit=crop&q=80',
                'description' => 'الحزمة الإنتاجية القصوى للمحاسبين والمبرمجين، أزرار نقر هادئة، عجلة تمرير MagSpeed فائقة السرعة.',
                'sales_price' => 750,
                'discount_price' => 620,
                'is_featured' => false,
                'is_deal' => true,
                'rating' => 4.9,
                'reviews_count' => 41,
                'stock' => 35,
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
                    'purchase_price' => $data['sales_price'] * 0.75,
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

        // 4. Create Demo Customer User and Link Accounting Party
        $arAccount = Account::where('code', '1103')->orWhere('name', 'like', '%عملاء%')->first();

        $party = Party::firstOrCreate(
            ['name' => 'م. محمود علي (عميل متجر)'],
            [
                'type' => 'customer',
                'phone' => '0599123456',
                'address' => 'غزة - شارع الرمال الرئيسي',
                'account_id' => $arAccount?->id,
            ]
        );

        $demoCustomer = User::updateOrCreate(
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
                'party_id' => $party->id,
            ]
        );

        // 5. Seed an existing sample order for this customer
        $existingOrder = Order::where('user_id', $demoCustomer->id)->first();
        if (!$existingOrder) {
            $sampleItem = Item::where('barcode', '690123450006')->first(); // Sony Headphones
            if ($sampleItem) {
                $invoice = Invoice::create([
                    'type' => 'sale',
                    'date' => now()->subDays(2)->toDateString(),
                    'party_id' => $party->id,
                    'store_id' => $store->id,
                    'notes' => 'فاتورة مبيعات طلب رقم ORD-DEMO-001 من المتجر الإلكتروني',
                ]);

                InvoiceLine::create([
                    'invoice_id' => $invoice->id,
                    'item_id' => $sampleItem->id,
                    'quantity' => 1,
                    'unit_price' => $sampleItem->effective_price,
                ]);

                $order = Order::create([
                    'order_number' => 'ORD-20260830-98421',
                    'user_id' => $demoCustomer->id,
                    'party_id' => $party->id,
                    'invoice_id' => $invoice->id,
                    'status' => 'processing',
                    'subtotal' => $sampleItem->effective_price,
                    'discount_amount' => 0,
                    'shipping_fee' => 0,
                    'total_amount' => $sampleItem->effective_price,
                    'payment_method' => 'cod',
                    'payment_status' => 'unpaid',
                    'shipping_name' => $demoCustomer->name,
                    'shipping_phone' => $demoCustomer->phone,
                    'shipping_address' => $demoCustomer->address,
                    'shipping_city' => $demoCustomer->city,
                    'notes' => 'طلب تجريبي مفعل مسبقاً',
                ]);

                OrderItem::create([
                    'order_id' => $order->id,
                    'item_id' => $sampleItem->id,
                    'item_name' => $sampleItem->name,
                    'quantity' => 1,
                    'unit_price' => $sampleItem->effective_price,
                    'total_price' => $sampleItem->effective_price,
                ]);
            }
        }
    }
}
