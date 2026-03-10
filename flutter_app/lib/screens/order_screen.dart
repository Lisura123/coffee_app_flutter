import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../providers/api_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});
}

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<CartItem> _cart = [];
  String _tableNumber = '';
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  List<Order> _myOrders = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMyOrders();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadMyOrders();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMyOrders() async {
    try {
      final data = await ApiService.getOrders(filter: 'active');
      if (mounted) setState(() => _myOrders = data);
    } catch (e) {
      debugPrint('Could not load orders: $e');
    }
  }

  int get _totalItems => _cart.fold(0, (sum, item) => sum + item.quantity);

  void _addToCart(MenuItem menuItem) {
    setState(() {
      final existingIdx = _cart.indexWhere(
        (item) => item.menuItem.id == menuItem.id,
      );
      if (existingIdx >= 0) {
        _cart[existingIdx].quantity++;
      } else {
        _cart.add(CartItem(menuItem: menuItem));
      }
    });
  }

  void _removeFromCart(String menuItemId) {
    setState(() {
      final existingIdx = _cart.indexWhere(
        (item) => item.menuItem.id == menuItemId,
      );
      if (existingIdx >= 0) {
        if (_cart[existingIdx].quantity > 1) {
          _cart[existingIdx].quantity--;
        } else {
          _cart.removeAt(existingIdx);
        }
      }
    });
  }

  int _getCartQuantity(String menuItemId) {
    final item = _cart
        .where((item) => item.menuItem.id == menuItemId)
        .firstOrNull;
    return item?.quantity ?? 0;
  }

  void _clearCart() {
    setState(() {
      _cart = [];
      _tableNumber = '';
      _notesController.clear();
    });
  }

  Future<void> _handleSubmitOrder() async {
    if (_cart.isEmpty) {
      _showMessage('Please add items to your order');
      return;
    }
    if (_tableNumber.isEmpty) {
      _showMessage('Please select a table');
      return;
    }

    final apiProvider = context.read<ApiProvider>();
    if (!apiProvider.isConnected) {
      _showMessage('No API connection. Please check your network.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final orderItems = _cart
          .map(
            (item) => {
              'menu_item_id': int.tryParse(item.menuItem.id) ?? 0,
              'menu_item_name': item.menuItem.name,
              'quantity': item.quantity,
            },
          )
          .toList();

      await apiProvider.createOrder(
        tableNumber: int.parse(_tableNumber),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        items: orderItems,
      );

      final itemsList = _cart
          .map((item) => '${item.quantity}x ${item.menuItem.name}')
          .join('\n');

      if (mounted) {
        _showSuccessDialog(
          'Order Placed! 🎉',
          'Table $_tableNumber\n\n$itemsList\n\nOrder sent to kitchen!',
          onOk: () {
            _clearCart();
            _loadMyOrders();
          },
        );
      }
    } catch (e) {
      debugPrint('Error submitting order: $e');
      if (mounted) {
        _showMessage(
          'Failed to send order: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(String title, String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOk?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiProvider = context.watch<ApiProvider>();
    final menuItems = apiProvider.menuItems.isNotEmpty
        ? apiProvider.menuItems
        : List<MenuItem>.from(defaultMenuItems);

    return Column(
      children: [
        // Connection Status Banner
        _buildConnectionBanner(apiProvider),

        // Header
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'New Order',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        // My Active Orders
        if (_myOrders.isNotEmpty) _buildMyOrdersSection(),

        // Table Selection
        _buildTableSelection(),

        // Beverages Header
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.coffee, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Beverages',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        // Menu Items
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await apiProvider.loadMenu();
              await _loadMyOrders();
            },
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: menuItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final quantity = _getCartQuantity(item.id);
                return _buildMenuItem(item, quantity);
              },
            ),
          ),
        ),

        // Cart Summary
        if (_cart.isNotEmpty) _buildCartSummary(),
      ],
    );
  }

  Widget _buildConnectionBanner(ApiProvider apiProvider) {
    if (apiProvider.status == ConnectionStatus.connected) {
      return const SizedBox.shrink();
    }

    final isConnecting = apiProvider.status == ConnectionStatus.connecting;
    final color = isConnecting ? AppColors.pendingColor : AppColors.error;
    final bgColor = isConnecting ? AppColors.pendingBg : AppColors.cancelledBg;
    final icon = isConnecting ? Icons.sync : Icons.cloud_off;
    final text = isConnecting
        ? 'Connecting to server...'
        : 'No server connection';

    return GestureDetector(
      onTap: isConnecting ? null : () => apiProvider.checkConnection(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: bgColor,
        child: Row(
          children: [
            isConnecting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (!isConnecting)
              Text(
                'Tap to retry',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyOrdersSection() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '📋 My Active Orders',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _myOrders.length,
              itemBuilder: (context, index) {
                final order = _myOrders[index];
                final config = statusConfig[order.status];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                        color: config?.color ?? AppColors.textSecondary,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.tag,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              Text(
                                '${order.tableNumber}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: config?.bgColor ?? AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  config?.icon ?? Icons.help,
                                  size: 12,
                                  color:
                                      config?.color ?? AppColors.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  config?.label ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        config?.color ??
                                        AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          order.items
                                  ?.map(
                                    (i) => '${i.quantity}x ${i.menuItemName}',
                                  )
                                  .join(', ') ??
                              '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSelection() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Table',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              final num = '${index + 1}';
              final isSelected = _tableNumber == num;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 4 ? 10 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _tableNumber = num),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.inputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        num,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item, int quantity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Row(
            children: [
              if (quantity > 0) ...[
                GestureDetector(
                  onTap: () => _removeFromCart(item.id),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.cancelledBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.remove,
                      size: 18,
                      color: AppColors.error,
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
              GestureDetector(
                onTap: () => _addToCart(item),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cart Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cart ($_totalItems ${_totalItems == 1 ? 'item' : 'items'})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: _clearCart,
                child: const Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cart Items
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _cart
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${item.quantity}x ${item.menuItem.name}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Notes Input
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: null,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'Add notes (e.g., no sugar, extra hot)',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSubmitting
                    ? AppColors.textTertiary
                    : AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isSubmitting ? 'Sending...' : 'Send to Kitchen',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
