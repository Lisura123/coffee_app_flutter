import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../providers/api_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});
}

// Beverage icons & colors for richer UI
const Map<String, IconData> _beverageIcons = {
  'water': Icons.water_drop_rounded,
  'tea': Icons.emoji_food_beverage_rounded,
  'coffee': Icons.coffee_rounded,
  'hot chocolate': Icons.local_cafe_rounded,
  'ginger tea': Icons.spa_rounded,
};

const Map<String, Color> _beverageColors = {
  'water': Color(0xFF0EA5E9),
  'tea': Color(0xFF10B981),
  'coffee': Color(0xFF92400E),
  'hot chocolate': Color(0xFFB45309),
  'ginger tea': Color(0xFFD97706),
};

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
  Map<String, String> _previousOrderStatuses = {};
  bool _isFirstLoad = true;

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

      // Detect status changes and send notifications
      if (!_isFirstLoad) {
        for (final order in data) {
          final prevStatus = _previousOrderStatuses[order.id];
          if (prevStatus != null && prevStatus != order.status) {
            final items =
                order.items
                    ?.map((i) => '${i.quantity}x ${i.menuItemName}')
                    .join(', ') ??
                '';
            NotificationService.showOrderStatusNotification(
              tableNumber: order.tableNumber,
              newStatus: order.status,
              items: items,
              id: int.tryParse(order.id) ?? 0,
            );
          }
        }
      }

      _previousOrderStatuses = {for (final o in data) o.id: o.status};
      _isFirstLoad = false;
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
        content: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog(String title, String message, {VoidCallback? onOk}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.completedBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 40,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onOk?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
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

        // My Active Orders
        if (_myOrders.isNotEmpty) _buildMyOrdersSection(),

        // Table Selection
        _buildTableSelection(),

        // Beverages Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.coffee_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Beverages',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${menuItems.length} items',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: menuItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
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
    final icon = isConnecting ? Icons.sync_rounded : Icons.cloud_off_rounded;
    final text = isConnecting
        ? 'Connecting to server...'
        : 'No server connection';

    return GestureDetector(
      onTap: isConnecting ? null : () => apiProvider.checkConnection(),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            isConnecting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(icon, size: 18, color: color),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.pendingBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 14,
                  color: AppColors.pendingColor,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Active Orders',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_myOrders.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _myOrders.length,
            itemBuilder: (context, index) {
              final order = _myOrders[index];
              final config = statusConfig[order.status];
              return Container(
                width: 170,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        config?.color.withValues(alpha: 0.3) ??
                        AppColors.border,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.table_restaurant_rounded,
                              size: 14,
                              color: config?.color ?? AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Table ${order.tableNumber}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: config?.color ?? AppColors.primary,
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
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            config?.label ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: config?.color ?? AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        order.items
                                ?.map((i) => '${i.quantity}x ${i.menuItemName}')
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
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTableSelection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.table_restaurant_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Select Table',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_tableNumber.isNotEmpty) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Table $_tableNumber',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                final num = '${index + 1}';
                final isSelected = _tableNumber == num;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _tableNumber = num),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? AppColors.primaryGradient
                              : null,
                          color: isSelected ? null : AppColors.inputBg,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              num,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item, int quantity) {
    final nameLower = item.name.toLowerCase();
    final itemIcon = _beverageIcons[nameLower] ?? Icons.local_drink_rounded;
    final itemColor = _beverageColors[nameLower] ?? AppColors.primary;
    final isInCart = quantity > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isInCart ? itemColor.withValues(alpha: 0.04) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInCart
              ? itemColor.withValues(alpha: 0.2)
              : AppColors.border.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Beverage icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: itemColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(itemIcon, size: 22, color: itemColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isInCart ? FontWeight.w700 : FontWeight.w600,
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
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.cancelledBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.remove_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                  ),
                ),
                SizedBox(
                  width: 38,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: itemColor,
                    ),
                  ),
                ),
              ],
              GestureDetector(
                onTap: () => _addToCart(item),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Cart Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$_totalItems ${_totalItems == 1 ? 'item' : 'items'}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _clearCart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cancelledBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 14,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _cart
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.menuItem.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: null,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: '📝 Add notes (e.g., no sugar, extra hot)',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
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
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSubmitting
                    ? AppColors.textTertiary
                    : AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSubmitting
                        ? Icons.hourglass_top_rounded
                        : Icons.send_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
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
