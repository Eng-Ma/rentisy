<?php

namespace Database\Seeders;

use App\Models\DeliveryZone;
use Illuminate\Database\Seeder;

class DeliveryZoneSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $zones = [
            ['name' => 'غزة - مدينة غزة والرمال والميناء', 'city' => 'غزة', 'delivery_fee' => 10.00, 'estimated_time' => 'خلال نفس اليوم (2-6 ساعات)'],
            ['name' => 'غزة - المنطقة الوسطى (دير البلح، النصيرات، البريج)', 'city' => 'غزة', 'delivery_fee' => 15.00, 'estimated_time' => 'خلال 24 ساعة'],
            ['name' => 'غزة - خانيونس ورفح', 'city' => 'غزة', 'delivery_fee' => 15.00, 'estimated_time' => 'خلال 24 ساعة'],
            ['name' => 'غزة - الشمال وجباليا وبيت لاهيا', 'city' => 'غزة', 'delivery_fee' => 12.00, 'estimated_time' => 'خلال 24 ساعة'],
            ['name' => 'رام الله والبيرة وبيتونيا', 'city' => 'رام الله', 'delivery_fee' => 20.00, 'estimated_time' => 'خلال 24-48 ساعة'],
            ['name' => 'نابلس والقرى المحيطة', 'city' => 'نابلس', 'delivery_fee' => 20.00, 'estimated_time' => 'خلال 24-48 ساعة'],
            ['name' => 'الخليل ودورا وحلحول والظاهرية', 'city' => 'الخليل', 'delivery_fee' => 20.00, 'estimated_time' => 'خلال 24-48 ساعة'],
            ['name' => 'بيت لحم وبيت جالا وبيت ساحور', 'city' => 'بيت لحم', 'delivery_fee' => 20.00, 'estimated_time' => 'خلال 24-48 ساعة'],
            ['name' => 'القدس الشريف وضواحيها (العيزرية، الرام، كفر عقب)', 'city' => 'القدس', 'delivery_fee' => 30.00, 'estimated_time' => 'خلال 24-48 ساعة'],
            ['name' => 'جنين ومحيطها وطوباس', 'city' => 'جنين', 'delivery_fee' => 25.00, 'estimated_time' => 'خلال 24-48 ساعة'],
            ['name' => 'طولكرم وقلقيلية وعنبتا', 'city' => 'طولكرم', 'delivery_fee' => 25.00, 'estimated_time' => 'خلال 24-48 ساعة'],
            ['name' => 'أريحا والأغوار والعوجا', 'city' => 'أريحا', 'delivery_fee' => 25.00, 'estimated_time' => 'خلال 24-48 ساعة'],
        ];

        foreach ($zones as $zone) {
            DeliveryZone::updateOrCreate(
                ['name' => $zone['name']],
                [
                    'city' => $zone['city'],
                    'delivery_fee' => $zone['delivery_fee'],
                    'estimated_time' => $zone['estimated_time'],
                    'is_active' => true,
                    'is_approved' => true,
                    'status' => 'approved',
                ]
            );
        }
    }
}
