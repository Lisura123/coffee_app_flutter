import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize the notification plugin (call once at app start)
  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Request notification permission on Android 13+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Show notification for a new order (Kitchen role)
  static Future<void> showNewOrderNotification({
    required int tableNumber,
    required String items,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'new_orders',
      'New Orders',
      channelDescription: 'Notifications for new incoming orders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, '🆕 New Order — Table $tableNumber', items, details);
  }

  /// Show notification when order status changes (Order/Salesperson role)
  static Future<void> showOrderStatusNotification({
    required int tableNumber,
    required String newStatus,
    required String items,
    int id = 0,
  }) async {
    String title;
    switch (newStatus) {
      case 'preparing':
        title = '👨‍🍳 Preparing — Table $tableNumber';
        break;
      case 'completed':
        title = '✅ Ready! — Table $tableNumber';
        break;
      case 'cancelled':
        title = '❌ Cancelled — Table $tableNumber';
        break;
      default:
        title = 'Order Update — Table $tableNumber';
    }

    const androidDetails = AndroidNotificationDetails(
      'order_updates',
      'Order Updates',
      channelDescription: 'Notifications when order status changes',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, items, details);
  }
}
