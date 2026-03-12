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

    public function store(\Illuminate\Http\Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'category' => 'string|max:255',
        ]);

        $item = MenuItem::firstOrCreate(
            ['name' => $request->name],
            [
                'name' => $request->name,
                'category' => $request->category ?? 'beverages',
                'available' => true,
            ]
        );

        return response()->json($item, 201);
    }
}
