<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Artisan;

Route::get('/', function () {
    return response()->json([
        'status' => 'ok',
        'message' => 'Showroom Orders API is running',
        'api_url' => url('/api'),
    ]);
});

// One-time setup route - Run this ONCE after uploading to Hostinger
// Visit: https://yourdomain.com/setup?key=showroom2024
// DELETE THIS ROUTE AFTER SETUP IS COMPLETE
Route::get('/setup', function () {
    $key = request()->query('key');
    if ($key !== 'showroom2024') {
        return response()->json(['error' => 'Invalid setup key'], 403);
    }

    try {
        // Run migrations
        Artisan::call('migrate', ['--force' => true]);
        $migrateOutput = Artisan::output();

        // Run seeders
        Artisan::call('db:seed', ['--force' => true]);
        $seedOutput = Artisan::output();

        // Create storage link
        Artisan::call('storage:link');
        $linkOutput = Artisan::output();

        return response()->json([
            'status' => 'success',
            'message' => 'Setup completed! Database tables created and seeded.',
            'migrate' => $migrateOutput,
            'seed' => $seedOutput,
            'storage_link' => $linkOutput,
            'note' => 'DELETE the /setup route from routes/web.php after this!'
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error',
            'message' => $e->getMessage()
        ], 500);
    }
});
