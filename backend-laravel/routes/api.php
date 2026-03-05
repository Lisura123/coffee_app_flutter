<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\MenuController;
use App\Http\Controllers\Api\OrderController;

// Health check
Route::get('/health', function () {
    return response()->json(['status' => 'ok', 'message' => 'Laravel API running']);
});

// Auth
Route::post('/login', [AuthController::class, 'login']);
Route::get('/users', [AuthController::class, 'users']);

// Menu
Route::get('/menu', [MenuController::class, 'index']);

// Orders
Route::get('/orders', [OrderController::class, 'index']);
Route::post('/orders', [OrderController::class, 'store']);
Route::get('/orders/{id}', [OrderController::class, 'show']);
Route::patch('/orders/{id}/status', [OrderController::class, 'updateStatus']);
Route::delete('/orders/{id}', [OrderController::class, 'destroy']);
