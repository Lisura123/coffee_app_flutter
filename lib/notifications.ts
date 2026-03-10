import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import { Platform } from 'react-native';

// Configure how notifications appear when app is in foreground
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

// Register for push notifications
export async function registerForPushNotifications(): Promise<string | null> {
  if (!Device.isDevice) {
    console.log('Push notifications only work on physical devices');
    return null;
  }

  // Check existing permissions
  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  let finalStatus = existingStatus;

  // Ask for permission if not already granted
  if (existingStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }

  if (finalStatus !== 'granted') {
    console.log('Push notification permission not granted');
    return null;
  }

  // Set notification channel for Android
  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('orders', {
      name: 'Order Updates',
      importance: Notifications.AndroidImportance.MAX,
      vibrationPattern: [0, 250, 250, 250],
      lightColor: '#0EA5E9',
      sound: 'default',
    });
  }

  return 'registered';
}

// Send a local notification
export async function sendLocalNotification(
  title: string,
  body: string,
  data?: Record<string, any>
) {
  await Notifications.scheduleNotificationAsync({
    content: {
      title,
      body,
      sound: 'default',
      data: data || {},
    },
    trigger: null, // Send immediately
  });
}

// Notification for kitchen: new order received
export async function notifyNewOrder(tableNumber: number, itemCount: number, createdBy?: string) {
  const byText = createdBy ? ` by ${createdBy}` : '';
  await sendLocalNotification(
    '🆕 New Order!',
    `Table ${tableNumber} — ${itemCount} item${itemCount > 1 ? 's' : ''}${byText}`,
    { type: 'new_order', tableNumber }
  );
}

// Notification for kitchen: order reminder (if pending too long)
export async function notifyOrderReminder(tableNumber: number, minutesAgo: number) {
  await sendLocalNotification(
    '⏰ Order Waiting',
    `Table ${tableNumber} order has been pending for ${minutesAgo} minutes`,
    { type: 'order_reminder', tableNumber }
  );
}

// Notification for salesperson: order status changed
export async function notifyOrderStatusChange(
  tableNumber: number,
  status: 'preparing' | 'completed' | 'cancelled'
) {
  const messages = {
    preparing: { title: '👨‍🍳 Order Being Prepared', body: `Your order for Table ${tableNumber} is now being prepared` },
    completed: { title: '✅ Order Ready!', body: `Order for Table ${tableNumber} is ready for pickup!` },
    cancelled: { title: '❌ Order Cancelled', body: `Order for Table ${tableNumber} has been cancelled` },
  };

  const msg = messages[status];
  await sendLocalNotification(msg.title, msg.body, { type: 'status_change', tableNumber, status });
}
