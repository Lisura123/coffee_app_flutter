<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $query = Order::with('items');

        // Status filter
        if ($request->has('status')) {
            $status = $request->status;
            if ($status === 'active') {
                $query->whereIn('status', ['pending', 'preparing']);
            } elseif ($status === 'history') {
                $query->whereIn('status', ['completed', 'cancelled']);
            } else {
                $query->where('status', $status);
            }
        }

        // Filter by salesperson
        if ($request->has('created_by')) {
            $query->where('created_by', $request->created_by);
        }

        $orders = $query->orderBy('created_at', 'desc')->get();
        return response()->json($orders);
    }

    public function store(Request $request)
    {
        $request->validate([
            'table_number' => 'required|integer',
            'items' => 'required|array|min:1',
            'items.*.menu_item_id' => 'required|integer',
            'items.*.menu_item_name' => 'required|string',
            'items.*.quantity' => 'required|integer|min:1',
        ]);

        try {
            DB::beginTransaction();

            $order = Order::create([
                'table_number' => $request->table_number,
                'status' => 'pending',
                'notes' => $request->notes,
                'created_by' => $request->created_by,
                'created_by_name' => $request->created_by_name,
            ]);

            foreach ($request->items as $item) {
                $order->items()->create([
                    'menu_item_id' => $item['menu_item_id'],
                    'menu_item_name' => $item['menu_item_name'],
                    'quantity' => $item['quantity'],
                ]);
            }

            DB::commit();

            $order->load('items');
            return response()->json($order, 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    public function show($id)
    {
        $order = Order::with('items')->find($id);

        if (!$order) {
            return response()->json(['error' => 'Order not found'], 404);
        }

        return response()->json($order);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:pending,preparing,completed,cancelled',
        ]);

        $order = Order::find($id);

        if (!$order) {
            return response()->json(['error' => 'Order not found'], 404);
        }

        $order->update(['status' => $request->status]);
        $order->load('items');

        return response()->json($order);
    }

    public function destroy($id)
    {
        $order = Order::find($id);

        if (!$order) {
            return response()->json(['error' => 'Order not found'], 404);
        }

        $order->delete();
        return response()->json(['message' => 'Order deleted']);
    }
}
