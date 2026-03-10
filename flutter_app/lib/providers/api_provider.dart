import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

enum ConnectionStatus { connecting, connected, disconnected }

class ApiProvider extends ChangeNotifier {
  ConnectionStatus _status = ConnectionStatus.connecting;
  List<MenuItem> _menuItems = [];
  List<Order> _orders = [];
  String? _lastError;
  Timer? _refreshTimer;

  ConnectionStatus get status => _status;
  List<MenuItem> get menuItems => _menuItems;
  List<Order> get orders => _orders;
  String? get lastError => _lastError;
  bool get isConnected => _status == ConnectionStatus.connected;

  ApiProvider() {
    _init();
  }

  Future<void> _init() async {
    await checkConnection();
    // Auto-refresh orders every 10 seconds, retry connection if disconnected
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_status == ConnectionStatus.connected) {
        refreshOrders();
      } else if (_status == ConnectionStatus.disconnected) {
        checkConnection();
      }
    });
  }

  /// Check if the API is reachable by hitting /health
  Future<bool> checkConnection({bool isRetry = false}) async {
    _status = ConnectionStatus.connecting;
    _lastError = null;
    notifyListeners();

    try {
      final healthy = await ApiService.healthCheck();
      if (healthy) {
        _status = ConnectionStatus.connected;
        _lastError = null;
        notifyListeners();
        // Load initial data
        await Future.wait([loadMenu(), refreshOrders()]);
        return true;
      } else {
        // Retry once automatically
        if (!isRetry) {
          await Future.delayed(const Duration(seconds: 2));
          return checkConnection(isRetry: true);
        }
        _status = ConnectionStatus.disconnected;
        _lastError = 'Could not reach server';
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Retry once automatically
      if (!isRetry) {
        await Future.delayed(const Duration(seconds: 2));
        return checkConnection(isRetry: true);
      }
      _status = ConnectionStatus.disconnected;
      _lastError = e.toString();
      debugPrint('Connection check failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// Load menu items from API
  Future<void> loadMenu() async {
    try {
      final data = await ApiService.getMenu();
      _menuItems = data;
      if (_status != ConnectionStatus.connected) {
        _status = ConnectionStatus.connected;
        _lastError = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Menu load error: $e');
      if (_menuItems.isEmpty) {
        _menuItems = List.from(defaultMenuItems);
        notifyListeners();
      }
    }
  }

  /// Refresh orders from API
  Future<void> refreshOrders({String? filter}) async {
    try {
      final data = await ApiService.getOrders(filter: filter);
      _orders = data;
      if (_status != ConnectionStatus.connected) {
        _status = ConnectionStatus.connected;
        _lastError = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Orders refresh error: $e');
    }
  }

  /// Create a new order
  Future<Map<String, dynamic>> createOrder({
    required int tableNumber,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final result = await ApiService.createOrder(
      tableNumber: tableNumber,
      notes: notes,
      items: items,
    );
    // Refresh orders after creating
    await refreshOrders(filter: 'active');
    return result;
  }

  /// Update order status
  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    await ApiService.updateOrderStatus(orderId, newStatus);
    await refreshOrders();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
