import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/api_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  List<Order> _orders = [];
  String _filter = 'active'; // 'active' or 'all'
  Timer? _refreshTimer;
  Set<String> _knownOrderIds = {};
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchOrders();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    try {
      final filterParam = _filter == 'active' ? 'active' : null;
      final data = await ApiService.getOrders(filter: filterParam);

      // Detect new pending orders and send notifications
      if (!_isFirstLoad) {
        for (final order in data) {
          if (!_knownOrderIds.contains(order.id) && order.status == 'pending') {
            final items =
                order.items
                    ?.map((i) => '${i.quantity}x ${i.menuItemName}')
                    .join(', ') ??
                '';
            NotificationService.showNewOrderNotification(
              tableNumber: order.tableNumber,
              items: items,
              id: int.tryParse(order.id) ?? 0,
            );
          }
        }
      }

      _knownOrderIds = data.map((o) => o.id).toSet();
      _isFirstLoad = false;
      if (mounted) setState(() => _orders = data);
    } catch (e) {
      debugPrint('Kitchen orders fetch error: $e');
      if (mounted) setState(() => _orders = []);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    // Update locally first for snappy UI
    setState(() {
      _orders = _orders
          .map(
            (order) => order.id == orderId
                ? order.copyWith(
                    status: newStatus,
                    updatedAt: DateTime.now().toIso8601String(),
                  )
                : order,
          )
          .toList();
    });

    try {
      await ApiService.updateOrderStatus(int.parse(orderId), newStatus);
      // Refresh to get server-confirmed data
      await _fetchOrders();
    } catch (e) {
      debugPrint('Status update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        // Revert by re-fetching
        await _fetchOrders();
      }
    }
  }

  void _handleStartPreparing(Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.preparingBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_rounded, size: 28, color: AppColors.preparingColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start Preparing?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Table ${order.tableNumber} — ${order.items?.map((i) => '${i.quantity}x ${i.menuItemName}').join(', ') ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _updateOrderStatus(order.id, 'preparing');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Start', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _handleMarkCompleted(Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.completedBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 28, color: AppColors.completedColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mark as Completed?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Table ${order.tableNumber} order is ready to serve',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _updateOrderStatus(order.id, 'completed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Complete', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';

      final hour = date.hour > 12 ? date.hour - 12 : date.hour;
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute $amPm';
    } catch (e) {
      return '';
    }
  }

  List<Order> get _filteredOrders {
    if (_filter == 'active') {
      return _orders
          .where((o) => o.status == 'pending' || o.status == 'preparing')
          .toList();
    }
    return _orders;
  }

  @override
  Widget build(BuildContext context) {
    final apiProvider = context.watch<ApiProvider>();
    final filteredOrders = _filteredOrders;
    final pendingCount = filteredOrders
        .where((o) => o.status == 'pending')
        .length;
    final preparingCount = filteredOrders
        .where((o) => o.status == 'preparing')
        .length;

    return Column(
      children: [
        // Connection Status Banner
        _buildConnectionBanner(apiProvider),

        // Summary chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _buildCountChip(
                icon: Icons.schedule_rounded,
                label: 'Pending',
                count: pendingCount,
                color: AppColors.pendingColor,
                bgColor: AppColors.pendingBg,
              ),
              const SizedBox(width: 10),
              _buildCountChip(
                icon: Icons.restaurant_rounded,
                label: 'Preparing',
                count: preparingCount,
                color: AppColors.preparingColor,
                bgColor: AppColors.preparingBg,
              ),
              const Spacer(),
              // Filter Tabs
              _buildFilterTab('Active', 'active'),
              const SizedBox(width: 8),
              _buildFilterTab('All', 'all'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Orders List
        Expanded(
          child: filteredOrders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.inputBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.restaurant_menu_rounded, size: 36, color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'active'
                              ? 'No active orders'
                              : 'No orders yet',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _filter == 'active'
                              ? 'New orders will appear here'
                              : 'Orders will appear once placed',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _fetchOrders(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredOrders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildOrderCard(filteredOrders[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCountChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isActive = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = value);
        _fetchOrders();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.kitchenGradient : null,
          color: isActive ? null : AppColors.inputBg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFEF6C00).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final config = statusConfig[order.status];
    final isPending = order.status == 'pending';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: isPending
            ? Border.all(color: AppColors.pendingColor.withValues(alpha: 0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header with colored top bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: config?.bgColor.withValues(alpha: 0.5) ?? AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.table_restaurant_rounded,
                            size: 16,
                            color: config?.color ?? AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Table ${order.tableNumber}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: config?.color ?? AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.access_time_rounded, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(order.createdAt),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: config?.bgColor ?? AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: config?.color.withValues(alpha: 0.3) ?? AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        config?.icon ?? Icons.help,
                        size: 14,
                        color: config?.color ?? AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        config?.label ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: config?.color ?? AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Order Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children:
                        order.items
                            ?.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      item.menuItemName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList() ??
                        [],
                  ),
                ),

                // Notes
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.pendingBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sticky_note_2_rounded, size: 16, color: Color(0xFF92400E)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.notes!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Action Buttons
                if (order.status == 'pending')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleStartPreparing(order),
                      icon: const Icon(Icons.restaurant_rounded, size: 20),
                      label: const Text(
                        'Start Preparing',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                if (order.status == 'preparing')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleMarkCompleted(order),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        'Mark Completed',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                if (order.status == 'completed')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.completedBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 18, color: AppColors.completedColor),
                        SizedBox(width: 8),
                        Text(
                          'Completed ✓',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.completedColor),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isConnecting ? null : () => apiProvider.checkConnection(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        ),
      ),
    );
  }
}
