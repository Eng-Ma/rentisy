<?php

namespace Database\Seeders;

use App\Models\User;
// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // User::factory(10)->create();

        User::updateOrCreate(
            ['email' => 'admin@admin.com'],
            [
                'name' => 'مدير النظام المحاسبي',
                'password' => bcrypt('password'),
                'role' => 'admin',
            ]
        );

        $this->call([
            AccountingSeeder::class,
            StorefrontSeeder::class,
        ]);
    }
}
