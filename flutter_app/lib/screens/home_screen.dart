import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'order_screen.dart';
import 'kitchen_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _handleSwitchRole() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch Role'),
        content: const Text('Go back to role selection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<RoleProvider>().clearRole();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleProvider>();
    final isSalesperson = roleProvider.isSalesperson;
    final isKitchen = roleProvider.isKitchen;

    // Build tabs based on role
    List<Widget> screens;
    List<BottomNavigationBarItem> navItems;
    String titleText;

    if (isSalesperson) {
      titleText = 'New Order';
      screens = [const OrderScreen()];
      navItems = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'New Order',
        ),
      ];
    } else if (isKitchen) {
      titleText = 'Kitchen';
      screens = [const KitchenScreen(), const HistoryScreen()];
      navItems = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.restaurant),
          label: 'Kitchen',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
      ];
    } else {
      titleText = 'Order System';
      screens = [const OrderScreen()];
      navItems = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'New Order',
        ),
      ];
    }

    // Ensure currentIndex is within bounds
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          titleText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _handleSwitchRole,
            tooltip: 'Switch role',
            icon: const Icon(Icons.swap_horiz_rounded,
                color: AppColors.textSecondary, size: 24),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: navItems.length > 1
          ? Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                backgroundColor: AppColors.surface,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textTertiary,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                items: navItems,
              ),
            )
          : null,
    );
  }
}
