<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MenuItem;

class MenuController extends Controller
{
    public function index()
    {
        $items = MenuItem::where('available', true)->get();
        return response()->json($items);
    }
}
