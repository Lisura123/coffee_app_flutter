<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $users = [
            ['username' => 'sales1', 'password' => '1234', 'name' => 'John Sales', 'role' => 'salesperson'],
            ['username' => 'sales2', 'password' => '1234', 'name' => 'Jane Sales', 'role' => 'salesperson'],
            ['username' => 'kitchen1', 'password' => '1234', 'name' => 'Chef Mike', 'role' => 'kitchen'],
            ['username' => 'kitchen2', 'password' => '1234', 'name' => 'Chef Sarah', 'role' => 'kitchen'],
        ];

        foreach ($users as $user) {
            User::firstOrCreate(
                ['username' => $user['username']],
                $user
            );
        }
    }
}
