import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';
import '../models/order.dart';

class ApiService {
  static const String baseUrl = 'https://cofee.cameralkstore.com/api';

  // Common headers for all requests
  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const Map<String, String> _acceptHeaders = {
    'Accept': 'application/json',
  };

  /// Safely decode JSON, throwing a readable error if the response is not JSON
  static dynamic _safeDecode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Server error (${response.statusCode}). Please try again later.',
      );
    }
  }

  // Health check - test API connectivity
  static Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'), headers: _acceptHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _safeDecode(response);
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
      headers: _jsonHeaders,
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode != 200) {
      final error = _safeDecode(response);
      throw Exception(error['error'] ?? 'Login failed');
    }

    return _safeDecode(response);
  }

  // Get menu items
  static Future<List<MenuItem>> getMenu() async {
    final response = await http.get(
      Uri.parse('$baseUrl/menu'),
      headers: _acceptHeaders,
    );
    if (response.statusCode != 200) throw Exception('Failed to fetch menu');

    final List<dynamic> data = _safeDecode(response);
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
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = _safeDecode(response);
      throw Exception(error['error'] ?? 'Failed to create order');
    }

    return _safeDecode(response);
  }

  // Get orders with optional filter and user filter
  static Future<List<Order>> getOrders({String? filter, int? userId}) async {
    final params = <String, String>{};
    if (filter != null) params['status'] = filter;
    if (userId != null) params['created_by'] = userId.toString();

    final uri = Uri.parse(
      '$baseUrl/orders',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await http.get(uri, headers: _acceptHeaders);
    if (response.statusCode != 200) throw Exception('Failed to fetch orders');

    final List<dynamic> data = _safeDecode(response);
    return data.map((item) => Order.fromJson(item)).toList();
  }

  // Update order status
  static Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String status,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: _jsonHeaders,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      final error = _safeDecode(response);
      throw Exception(error['error'] ?? 'Failed to update order');
    }

    return _safeDecode(response);
  }

  // Delete order
  static Future<void> deleteOrder(int orderId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: _acceptHeaders,
    );
    if (response.statusCode != 200) throw Exception('Failed to delete order');
  }

  // Create menu item
  static Future<Map<String, dynamic>> createMenuItem({
    required String name,
    String category = 'beverages',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/menu'),
      headers: _jsonHeaders,
      body: jsonEncode({'name': name, 'category': category}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = _safeDecode(response);
      throw Exception(
        error['error'] ?? error['message'] ?? 'Failed to add menu item',
      );
    }

    return _safeDecode(response);
  }

  // Update menu item
  static Future<Map<String, dynamic>> updateMenuItem({
    required int id,
    required String name,
    String category = 'beverages',
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/menu/$id'),
      headers: _jsonHeaders,
      body: jsonEncode({'name': name, 'category': category}),
    );

    if (response.statusCode != 200) {
      final error = _safeDecode(response);
      throw Exception(
        error['error'] ?? error['message'] ?? 'Failed to update menu item',
      );
    }

    return _safeDecode(response);
  }

  // Delete menu item
  static Future<void> deleteMenuItem(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/menu/$id'),
      headers: _acceptHeaders,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = _safeDecode(response);
      throw Exception(
        error['error'] ?? error['message'] ?? 'Failed to delete menu item',
      );
    }
  }
}
