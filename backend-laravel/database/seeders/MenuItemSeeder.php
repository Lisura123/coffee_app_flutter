<?php

namespace Database\Seeders;

use App\Models\MenuItem;
use Illuminate\Database\Seeder;

class MenuItemSeeder extends Seeder
{
    public function run(): void
    {
        $items = [
            ['name' => 'Water', 'category' => 'beverages', 'available' => true],
            ['name' => 'Tea', 'category' => 'beverages', 'available' => true],
            ['name' => 'Coffee', 'category' => 'beverages', 'available' => true],
            ['name' => 'Hot Chocolate', 'category' => 'beverages', 'available' => true],
        ];

        foreach ($items as $item) {
            MenuItem::firstOrCreate(
                ['name' => $item['name']],
                $item
            );
        }
    }
}
