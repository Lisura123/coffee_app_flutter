import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';
import '../models/order.dart';

class ApiService {
  static const String baseUrl = 'https://cofee.cameralkstore.com/api';

  // Health check - test API connectivity
  static Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  // Login
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Login failed');
    }

    return jsonDecode(response.body);
  }

  // Get menu items
  static Future<List<MenuItem>> getMenu() async {
    final response = await http.get(Uri.parse('$baseUrl/menu'));
    if (response.statusCode != 200) throw Exception('Failed to fetch menu');

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => MenuItem.fromJson(item)).toList();
  }

  // Create order
  static Future<Map<String, dynamic>> createOrder({
    required int tableNumber,
    String? notes,
    required List<Map<String, dynamic>> items,
    int? createdBy,
    String? createdByName,
  }) async {
    final body = {
      'table_number': tableNumber,
      'items': items,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
      if (createdByName != null) 'created_by_name': createdByName,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to create order');
    }

    return jsonDecode(response.body);
  }

  // Get orders with optional filter and user filter
  static Future<List<Order>> getOrders({String? filter, int? userId}) async {
    final params = <String, String>{};
    if (filter != null) params['status'] = filter;
    if (userId != null) params['created_by'] = userId.toString();

    final uri = Uri.parse(
      '$baseUrl/orders',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('Failed to fetch orders');

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => Order.fromJson(item)).toList();
  }

  // Update order status
  static Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String status,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update order');
    }

    return jsonDecode(response.body);
  }

  // Delete order
  static Future<void> deleteOrder(int orderId) async {
    final response = await http.delete(Uri.parse('$baseUrl/orders/$orderId'));
    if (response.statusCode != 200) throw Exception('Failed to delete order');
  }
}
