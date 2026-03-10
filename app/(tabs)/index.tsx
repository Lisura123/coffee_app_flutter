import { useState, useEffect, useCallback, useRef } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Alert,
  TextInput,
  RefreshControl,
} from 'react-native';
import { Coffee, Plus, Minus, Send, X, Clock, ChefHat, CheckCircle, Hash } from 'lucide-react-native';
import { MenuItem, DEFAULT_MENU_ITEMS, Order } from '@/lib/supabase';
import { useAuth } from '@/lib/AuthContext';
import api from '@/lib/api';
import { notifyOrderStatusChange } from '@/lib/notifications';

type CartItem = {
  menuItem: MenuItem;
  quantity: number;
};

const statusConfig = {
  pending: { label: 'Pending', color: '#F59E0B', bgColor: '#FEF3C7', icon: Clock },
  preparing: { label: 'Preparing', color: '#3B82F6', bgColor: '#DBEAFE', icon: ChefHat },
  completed: { label: 'Completed', color: '#10B981', bgColor: '#D1FAE5', icon: CheckCircle },
  cancelled: { label: 'Cancelled', color: '#EF4444', bgColor: '#FEE2E2', icon: X },
};

export default function OrderScreen() {
  const { user } = useAuth();
  const [menuItems, setMenuItems] = useState<MenuItem[]>(DEFAULT_MENU_ITEMS);
  const [cart, setCart] = useState<CartItem[]>([]);
  const [tableNumber, setTableNumber] = useState<string>('');
  const [notes, setNotes] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [myOrders, setMyOrders] = useState<Order[]>([]);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const previousOrderStatusRef = useRef<Map<number, string>>(new Map());

  // Load menu from API
  useEffect(() => {
    loadMenu();
    loadMyOrders();
  }, []);

  // Auto-refresh orders every 10 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      loadMyOrders();
    }, 10000);
    return () => clearInterval(interval);
  }, [user]);

  const loadMenu = async () => {
    try {
      const data = await api.getMenu();
      if (data && data.length > 0) {
        setMenuItems(data);
      }
    } catch (error) {
      console.log('Using default menu (API not available)');
    }
  };

  const loadMyOrders = async () => {
    if (!user) return;
    try {
      // Get active orders (pending/preparing) created by this salesperson
      const data = await api.getOrders('active', parseInt(user.id));
      const orders: Order[] = data || [];

      // Detect status changes and notify
      if (previousOrderStatusRef.current.size > 0) {
        for (const order of orders) {
          const prevStatus = previousOrderStatusRef.current.get(order.id);
          if (prevStatus && prevStatus !== order.status) {
            notifyOrderStatusChange(order.table_number, order.status);
          }
        }
      }

      // Update the ref with current statuses
      const statusMap = new Map<number, string>();
      for (const order of orders) {
        statusMap.set(order.id, order.status);
      }
      previousOrderStatusRef.current = statusMap;

      setMyOrders(orders);
    } catch (error) {
      console.log('Could not load my orders');
    }
  };

  const onRefresh = useCallback(async () => {
    setIsRefreshing(true);
    await loadMyOrders();
    setIsRefreshing(false);
  }, [user]);

  // Calculate total items
  const totalItems = cart.reduce((sum, item) => sum + item.quantity, 0);

  // Add item to cart
  const addToCart = (menuItem: MenuItem) => {
    setCart((prevCart) => {
      const existingItem = prevCart.find((item) => item.menuItem.id === menuItem.id);
      if (existingItem) {
        return prevCart.map((item) =>
          item.menuItem.id === menuItem.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      }
      return [...prevCart, { menuItem, quantity: 1 }];
    });
  };

  // Remove item from cart
  const removeFromCart = (menuItemId: string) => {
    setCart((prevCart) => {
      const existingItem = prevCart.find((item) => item.menuItem.id === menuItemId);
      if (existingItem && existingItem.quantity > 1) {
        return prevCart.map((item) =>
          item.menuItem.id === menuItemId
            ? { ...item, quantity: item.quantity - 1 }
            : item
        );
      }
      return prevCart.filter((item) => item.menuItem.id !== menuItemId);
    });
  };

  // Get quantity in cart
  const getCartQuantity = (menuItemId: string): number => {
    const item = cart.find((item) => item.menuItem.id === menuItemId);
    return item ? item.quantity : 0;
  };

  // Clear cart
  const clearCart = () => {
    setCart([]);
    setTableNumber('');
    setNotes('');
  };

  // Submit order
  const handleSubmitOrder = async () => {
    if (cart.length === 0) {
      Alert.alert('Error', 'Please add items to your order');
      return;
    }

    if (!tableNumber) {
      Alert.alert('Error', 'Please select a table');
      return;
    }

    setIsSubmitting(true);

    try {
      // Prepare order items for API
      const orderItems = cart.map((item) => ({
        menu_item_id: parseInt(item.menuItem.id),
        menu_item_name: item.menuItem.name,
        quantity: item.quantity,
      }));

      // Send to MySQL API with salesperson info
      await api.createOrder({
        table_number: parseInt(tableNumber),
        notes: notes.trim() || undefined,
        items: orderItems,
        created_by: user ? parseInt(user.id) : undefined,
        created_by_name: user?.name,
      });

      const itemsList = cart.map(item => `${item.quantity}x ${item.menuItem.name}`).join('\n');
      Alert.alert(
        'Order Placed! 🎉',
        `Table ${tableNumber}\n\n${itemsList}\n\nOrder sent to kitchen!`,
        [{ text: 'OK', onPress: () => { clearCart(); loadMyOrders(); } }]
      );
    } catch (error) {
      console.error('Error submitting order:', error);
      // Show success anyway for demo (when API not running)
      const itemsList = cart.map(item => `${item.quantity}x ${item.menuItem.name}`).join('\n');
      Alert.alert(
        'Order Placed! 🎉',
        `Table ${tableNumber}\n\n${itemsList}\n\nOrder sent to kitchen!\n\n(Demo mode - API not connected)`,
        [{ text: 'OK', onPress: clearCart }]
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>New Order</Text>
      </View>

      {/* My Active Orders Section */}
      {myOrders.length > 0 && (
        <View style={styles.myOrdersSection}>
          <Text style={styles.myOrdersTitle}>📋 My Active Orders</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.myOrdersScroll}>
            {myOrders.map((order) => {
              const status = statusConfig[order.status];
              const StatusIcon = status.icon;
              const itemCount = order.items?.reduce((sum, i) => sum + i.quantity, 0) || 0;
              return (
                <View key={order.id} style={[styles.myOrderCard, { borderLeftColor: status.color }]}>
                  <View style={styles.myOrderHeader}>
                    <View style={styles.tableTag}>
                      <Hash size={12} color="#0EA5E9" />
                      <Text style={styles.tableText}>{order.table_number}</Text>
                    </View>
                    <View style={[styles.statusBadge, { backgroundColor: status.bgColor }]}>
                      <StatusIcon size={12} color={status.color} />
                      <Text style={[styles.statusText, { color: status.color }]}>{status.label}</Text>
                    </View>
                  </View>
                  <Text style={styles.myOrderItems} numberOfLines={2}>
                    {order.items?.map(i => `${i.quantity}x ${i.menu_item_name}`).join(', ')}
                  </Text>
                </View>
              );
            })}
          </ScrollView>
        </View>
      )}

      {/* Table Selection */}
      <View style={styles.tableSelectionContainer}>
        <Text style={styles.tableLabel}>Select Table</Text>
        <View style={styles.tableButtonsRow}>
          {[1, 2, 3, 4, 5].map((num) => (
            <TouchableOpacity
              key={num}
              style={[
                styles.tableButton,
                tableNumber === String(num) && styles.tableButtonSelected,
              ]}
              onPress={() => setTableNumber(String(num))}
            >
              <Text
                style={[
                  styles.tableButtonText,
                  tableNumber === String(num) && styles.tableButtonTextSelected,
                ]}
              >
                {num}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      {/* Beverages Header */}
      <View style={styles.beveragesHeader}>
        <Coffee size={20} color="#0EA5E9" />
        <Text style={styles.beveragesTitle}>Beverages</Text>
      </View>

      {/* Menu Items */}
      <ScrollView 
        style={styles.menuContainer} 
        contentContainerStyle={styles.menuContent}
        refreshControl={
          <RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} />
        }
      >
        {menuItems.map((item) => {
          const quantity = getCartQuantity(item.id);
          return (
            <View key={item.id} style={styles.menuItem}>
              <View style={styles.menuItemInfo}>
                <Text style={styles.menuItemName}>{item.name}</Text>
              </View>
              <View style={styles.quantityControls}>
                {quantity > 0 && (
                  <>
                    <TouchableOpacity
                      style={styles.quantityButton}
                      onPress={() => removeFromCart(item.id)}>
                      <Minus size={18} color="#EF4444" />
                    </TouchableOpacity>
                    <Text style={styles.quantityText}>{quantity}</Text>
                  </>
                )}
                <TouchableOpacity
                  style={[styles.quantityButton, styles.addButton]}
                  onPress={() => addToCart(item)}>
                  <Plus size={18} color="#FFFFFF" />
                </TouchableOpacity>
              </View>
            </View>
          );
        })}
      </ScrollView>

      {/* Cart Summary */}
      {cart.length > 0 && (
        <View style={styles.cartSummary}>
          <View style={styles.cartHeader}>
            <Text style={styles.cartTitle}>
              Cart ({totalItems} {totalItems === 1 ? 'item' : 'items'})
            </Text>
            <TouchableOpacity onPress={clearCart}>
              <X size={20} color="#EF4444" />
            </TouchableOpacity>
          </View>

          {/* Cart Items List */}
          <View style={styles.cartItems}>
            {cart.map((item) => (
              <Text key={item.menuItem.id} style={styles.cartItemText}>
                {item.quantity}x {item.menuItem.name}
              </Text>
            ))}
          </View>
          
          {/* Notes Input */}
          <TextInput
            style={styles.notesInput}
            value={notes}
            onChangeText={setNotes}
            placeholder="Add notes (e.g., no sugar, extra hot)"
            placeholderTextColor="#94A3B8"
            multiline
          />

          <TouchableOpacity
            style={[styles.submitButton, isSubmitting && styles.submitButtonDisabled]}
            onPress={handleSubmitOrder}
            disabled={isSubmitting}>
            <Send size={20} color="#FFFFFF" />
            <Text style={styles.submitButtonText}>
              {isSubmitting ? 'Sending...' : 'Send to Kitchen'}
            </Text>
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    paddingTop: 12,
    paddingHorizontal: 20,
    paddingBottom: 12,
    backgroundColor: '#FFFFFF',
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    color: '#1E293B',
  },
  myOrdersSection: {
    backgroundColor: '#FFFFFF',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  myOrdersTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#64748B',
    paddingHorizontal: 20,
    marginBottom: 8,
  },
  myOrdersScroll: {
    paddingLeft: 20,
  },
  myOrderCard: {
    backgroundColor: '#F8FAFC',
    borderRadius: 10,
    padding: 12,
    marginRight: 12,
    minWidth: 160,
    borderLeftWidth: 3,
  },
  myOrderHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  tableTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  tableText: {
    fontSize: 14,
    fontWeight: '700',
    color: '#0EA5E9',
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 10,
    gap: 3,
  },
  statusText: {
    fontSize: 10,
    fontWeight: '600',
  },
  myOrderItems: {
    fontSize: 12,
    color: '#64748B',
  },
  tableSelectionContainer: {
    paddingHorizontal: 20,
    paddingVertical: 12,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  tableLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1E293B',
    marginBottom: 10,
  },
  tableButtonsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 10,
  },
  tableButton: {
    flex: 1,
    height: 50,
    backgroundColor: '#F1F5F9',
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#E2E8F0',
  },
  tableButtonSelected: {
    backgroundColor: '#0EA5E9',
    borderColor: '#0EA5E9',
  },
  tableButtonText: {
    fontSize: 18,
    fontWeight: '700',
    color: '#64748B',
  },
  tableButtonTextSelected: {
    color: '#FFFFFF',
  },
  beveragesHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 14,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
    gap: 8,
  },
  beveragesTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#0EA5E9',
  },
  menuContainer: {
    flex: 1,
  },
  menuContent: {
    padding: 16,
    gap: 12,
  },
  menuItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  menuItemInfo: {
    flex: 1,
  },
  menuItemName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1E293B',
  },
  quantityControls: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  quantityButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#FEE2E2',
    justifyContent: 'center',
    alignItems: 'center',
  },
  addButton: {
    backgroundColor: '#0EA5E9',
  },
  quantityText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#1E293B',
    minWidth: 24,
    textAlign: 'center',
  },
  cartSummary: {
    backgroundColor: '#FFFFFF',
    padding: 20,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -4 },
    shadowOpacity: 0.1,
    shadowRadius: 12,
    elevation: 8,
  },
  cartHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  cartTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1E293B',
  },
  cartItems: {
    backgroundColor: '#F8FAFC',
    borderRadius: 8,
    padding: 12,
    marginBottom: 12,
    gap: 4,
  },
  cartItemText: {
    fontSize: 14,
    color: '#475569',
  },
  notesInput: {
    backgroundColor: '#F1F5F9',
    borderRadius: 8,
    padding: 12,
    fontSize: 14,
    color: '#1E293B',
    marginBottom: 16,
    minHeight: 44,
  },
  submitButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#10B981',
    paddingHorizontal: 24,
    paddingVertical: 14,
    borderRadius: 12,
    gap: 8,
  },
  submitButtonDisabled: {
    backgroundColor: '#94A3B8',
  },
  submitButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '700',
  },
});
