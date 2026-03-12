import { useState, useEffect, useCallback, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  RefreshControl,
  Alert,
} from 'react-native';
import { Clock, CheckCircle, ChefHat, XCircle, Hash } from 'lucide-react-native';
import { Order } from '@/lib/supabase';
import api from '@/lib/api';
import { notifyNewOrder } from '@/lib/notifications';

const statusConfig = {
  pending: { label: 'Pending', color: '#F59E0B', bgColor: '#FEF3C7', icon: Clock },
  preparing: { label: 'Preparing', color: '#3B82F6', bgColor: '#DBEAFE', icon: ChefHat },
  completed: { label: 'Completed', color: '#10B981', bgColor: '#D1FAE5', icon: CheckCircle },
  cancelled: { label: 'Cancelled', color: '#EF4444', bgColor: '#FEE2E2', icon: XCircle },
};

export default function KitchenScreen() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [filter, setFilter] = useState<'active' | 'all'>('active');
  const previousOrderIdsRef = useRef<Set<string>>(new Set());

  const fetchOrders = async (isRefresh = false) => {
    if (isRefresh) setIsRefreshing(true);
    else setIsLoading(true);

    try {
      const filterParam = filter === 'active' ? 'active' : undefined;
      const data = await api.getOrders(filterParam);
      
      // Check for new orders and send notification
      if (data && data.length > 0 && previousOrderIdsRef.current.size > 0) {
        const newOrders = data.filter(
          (order: Order) => !previousOrderIdsRef.current.has(String(order.id)) && order.status === 'pending'
        );
        for (const order of newOrders) {
          const itemCount = order.items?.length || 0;
          notifyNewOrder(order.table_number, itemCount, (order as any).created_by_name);
        }
      }
      
      // Update tracked order IDs
      previousOrderIdsRef.current = new Set(data.map((o: Order) => String(o.id)));
      setOrders(data);
    } catch (error) {
      console.log('API not available');
      setOrders([]);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, [filter]);

  // Auto-refresh every 10 seconds to check for new orders
  useEffect(() => {
    const interval = setInterval(() => {
      fetchOrders();
    }, 10000);
    return () => clearInterval(interval);
  }, [filter]);

  const onRefresh = useCallback(() => {
    fetchOrders(true);
  }, [filter]);

  const updateOrderStatus = async (orderId: string, newStatus: Order['status']) => {
    // Update locally first
    setOrders(prev => 
      prev.map(order => 
        order.id === orderId 
          ? { ...order, status: newStatus, updated_at: new Date().toISOString() }
          : order
      )
    );

    // Try to update in database
    try {
      await api.updateOrderStatus(parseInt(orderId), newStatus);
    } catch (error) {
      console.log('Local update only (API not connected)');
    }
  };

  const handleStartPreparing = (order: Order) => {
    Alert.alert(
      'Start Preparing',
      `Start preparing order for Table ${order.table_number}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Start', onPress: () => updateOrderStatus(order.id, 'preparing') },
      ]
    );
  };

  const handleMarkCompleted = (order: Order) => {
    Alert.alert(
      'Mark as Completed',
      `Mark order for Table ${order.table_number} as completed?`,
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Complete', onPress: () => updateOrderStatus(order.id, 'completed') },
      ]
    );
  };

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins} min ago`;
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  };

  const filteredOrders = filter === 'active'
    ? orders.filter(o => o.status === 'pending' || o.status === 'preparing')
    : orders;

  const renderOrder = ({ item }: { item: Order }) => {
    const status = statusConfig[item.status];
    const StatusIcon = status.icon;

    return (
      <View style={styles.orderCard}>
        {/* Order Header */}
        <View style={styles.orderHeader}>
          <View style={styles.tableInfo}>
            <View style={styles.tableBadge}>
              <Hash size={16} color="#0EA5E9" />
              <Text style={styles.tableNumber}>{item.table_number}</Text>
            </View>
            <Text style={styles.orderTime}>{formatTime(item.created_at)}</Text>
          </View>
          <View style={[styles.statusBadge, { backgroundColor: status.bgColor }]}>
            <StatusIcon size={14} color={status.color} />
            <Text style={[styles.statusText, { color: status.color }]}>{status.label}</Text>
          </View>
        </View>

        {/* Order Items */}
        <View style={styles.orderItems}>
          {item.items?.map((orderItem, index) => (
            <View key={orderItem.id || index} style={styles.orderItemRow}>
              <Text style={styles.itemQuantity}>{orderItem.quantity}x</Text>
              <Text style={styles.itemName}>{orderItem.menu_item_name}</Text>
            </View>
          ))}
        </View>

        {/* Notes */}
        {item.notes && (
          <View style={styles.notesContainer}>
            <Text style={styles.notesLabel}>Notes:</Text>
            <Text style={styles.notesText}>{item.notes}</Text>
          </View>
        )}

        {/* Action Buttons */}
        <View style={styles.actionButtons}>
          {item.status === 'pending' && (
            <TouchableOpacity
              style={[styles.actionButton, styles.prepareButton]}
              onPress={() => handleStartPreparing(item)}>
              <ChefHat size={18} color="#FFFFFF" />
              <Text style={styles.actionButtonText}>Start Preparing</Text>
            </TouchableOpacity>
          )}
          {item.status === 'preparing' && (
            <TouchableOpacity
              style={[styles.actionButton, styles.completeButton]}
              onPress={() => handleMarkCompleted(item)}>
              <CheckCircle size={18} color="#FFFFFF" />
              <Text style={styles.actionButtonText}>Mark Completed</Text>
            </TouchableOpacity>
          )}
          {item.status === 'completed' && (
            <View style={styles.completedBanner}>
              <CheckCircle size={18} color="#10B981" />
              <Text style={styles.completedText}>Order Completed</Text>
            </View>
          )}
        </View>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Kitchen Orders</Text>
        <Text style={styles.headerSubtitle}>
          {filteredOrders.filter(o => o.status === 'pending').length} pending
        </Text>
      </View>

      {/* Filter Tabs */}
      <View style={styles.filterContainer}>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'active' && styles.filterTabActive]}
          onPress={() => setFilter('active')}>
          <Text style={[styles.filterText, filter === 'active' && styles.filterTextActive]}>
            Active Orders
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'all' && styles.filterTabActive]}
          onPress={() => setFilter('all')}>
          <Text style={[styles.filterText, filter === 'all' && styles.filterTextActive]}>
            All Orders
          </Text>
        </TouchableOpacity>
      </View>

      {/* Orders List */}
      {filteredOrders.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyTitle}>No orders</Text>
          <Text style={styles.emptySubtitle}>
            {filter === 'active' 
              ? 'No active orders at the moment' 
              : 'No orders have been placed yet'}
          </Text>
        </View>
      ) : (
        <FlatList
          data={filteredOrders}
          renderItem={renderOrder}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContent}
          refreshControl={
            <RefreshControl
              refreshing={isRefreshing}
              onRefresh={onRefresh}
              tintColor="#0EA5E9"
            />
          }
        />
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
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 12,
    paddingHorizontal: 20,
    paddingBottom: 12,
    backgroundColor: '#FFFFFF',
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: '#1E293B',
  },
  headerSubtitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#F59E0B',
    backgroundColor: '#FEF3C7',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
  },
  filterContainer: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    paddingVertical: 12,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
    gap: 12,
  },
  filterTab: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#F1F5F9',
  },
  filterTabActive: {
    backgroundColor: '#0EA5E9',
  },
  filterText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#64748B',
  },
  filterTextActive: {
    color: '#FFFFFF',
  },
  listContent: {
    padding: 16,
    gap: 16,
  },
  orderCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  orderHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  tableInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  tableBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#E0F2FE',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    gap: 4,
  },
  tableNumber: {
    fontSize: 18,
    fontWeight: '700',
    color: '#0EA5E9',
  },
  orderTime: {
    fontSize: 14,
    color: '#64748B',
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 12,
    gap: 4,
  },
  statusText: {
    fontSize: 12,
    fontWeight: '600',
  },
  orderItems: {
    backgroundColor: '#F8FAFC',
    borderRadius: 12,
    padding: 12,
    gap: 8,
    marginBottom: 12,
  },
  orderItemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  itemQuantity: {
    fontSize: 14,
    fontWeight: '700',
    color: '#0EA5E9',
    minWidth: 28,
  },
  itemName: {
    fontSize: 15,
    color: '#1E293B',
    fontWeight: '500',
  },
  notesContainer: {
    backgroundColor: '#FEF3C7',
    borderRadius: 8,
    padding: 10,
    marginBottom: 12,
    flexDirection: 'row',
    gap: 6,
  },
  notesLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: '#92400E',
  },
  notesText: {
    fontSize: 13,
    color: '#92400E',
    flex: 1,
  },
  orderTotal: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#E2E8F0',
    marginBottom: 12,
  },
  totalLabel: {
    fontSize: 14,
    color: '#64748B',
  },
  totalAmount: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1E293B',
  },
  actionButtons: {
    gap: 8,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    borderRadius: 10,
    gap: 8,
  },
  prepareButton: {
    backgroundColor: '#3B82F6',
  },
  completeButton: {
    backgroundColor: '#10B981',
  },
  actionButtonText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '600',
  },
  completedBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    backgroundColor: '#D1FAE5',
    borderRadius: 10,
    gap: 8,
  },
  completedText: {
    color: '#10B981',
    fontSize: 15,
    fontWeight: '600',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 40,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#1E293B',
    marginBottom: 8,
  },
  emptySubtitle: {
    fontSize: 16,
    color: '#64748B',
    textAlign: 'center',
  },
});
