import 'package:flutter/material.dart';

/// App-wide color constants matching the original design
class AppColors {
  static const Color primary = Color(0xFF0EA5E9);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color inputBg = Color(0xFFF1F5F9);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Status colors
  static const Color pendingColor = Color(0xFFF59E0B);
  static const Color pendingBg = Color(0xFFFEF3C7);
  static const Color preparingColor = Color(0xFF3B82F6);
  static const Color preparingBg = Color(0xFFDBEAFE);
  static const Color completedColor = Color(0xFF10B981);
  static const Color completedBg = Color(0xFFD1FAE5);
  static const Color cancelledColor = Color(0xFFEF4444);
  static const Color cancelledBg = Color(0xFFFEE2E2);
}

class StatusConfig {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const StatusConfig({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.icon,
  });
}

final Map<String, StatusConfig> statusConfig = {
  'pending': const StatusConfig(
    label: 'Pending',
    color: AppColors.pendingColor,
    bgColor: AppColors.pendingBg,
    icon: Icons.schedule,
  ),
  'preparing': const StatusConfig(
    label: 'Preparing',
    color: AppColors.preparingColor,
    bgColor: AppColors.preparingBg,
    icon: Icons.restaurant,
  ),
  'completed': const StatusConfig(
    label: 'Completed',
    color: AppColors.completedColor,
    bgColor: AppColors.completedBg,
    icon: Icons.check_circle,
  ),
  'cancelled': const StatusConfig(
    label: 'Cancelled',
    color: AppColors.cancelledColor,
    bgColor: AppColors.cancelledBg,
    icon: Icons.cancel,
  ),
};
