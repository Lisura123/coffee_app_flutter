import { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  RefreshControl,
} from 'react-native';
import { ShoppingBag, Clock, CheckCircle, Hash, ChefHat, XCircle } from 'lucide-react-native';
import { Order } from '@/lib/supabase';
import api from '@/lib/api';

const statusConfig = {
  pending: { label: 'Pending', color: '#F59E0B', bgColor: '#FEF3C7', icon: Clock },
  preparing: { label: 'Preparing', color: '#3B82F6', bgColor: '#DBEAFE', icon: ChefHat },
  completed: { label: 'Completed', color: '#10B981', bgColor: '#D1FAE5', icon: CheckCircle },
  cancelled: { label: 'Cancelled', color: '#EF4444', bgColor: '#FEE2E2', icon: XCircle },
};

export default function HistoryScreen() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const fetchOrders = async (isRefresh = false) => {
    if (isRefresh) setIsRefreshing(true);

    try {
      console.log('Fetching history orders...');
      const data = await api.getOrders('history');
      console.log('History orders received:', data?.length || 0, 'orders');
      setOrders(data || []);
    } catch (error) {
      console.log('History API error:', error);
      setOrders([]);
    } finally {
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, []);

  const onRefresh = useCallback(() => {
    fetchOrders(true);
  }, []);

  // Calculate stats
  const completedOrders = orders.filter(o => o.status === 'completed');
  const totalItems = completedOrders.reduce((sum, o) => 
    sum + (o.items?.reduce((itemSum, item) => itemSum + item.quantity, 0) || 0), 0
  );

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString('en-US', { 
      hour: 'numeric', 
      minute: '2-digit',
      hour12: true 
    });
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (date.toDateString() === today.toDateString()) {
      return 'Today';
    } else if (date.toDateString() === yesterday.toDateString()) {
      return 'Yesterday';
    }
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const renderOrder = ({ item }: { item: Order }) => {
    const status = statusConfig[item.status];
    const StatusIcon = status.icon;
    const itemCount = item.items?.reduce((sum, i) => sum + i.quantity, 0) || 0;

    return (
      <View style={styles.orderCard}>
        <View style={styles.orderHeader}>
          <View style={styles.tableInfo}>
            <View style={styles.tableBadge}>
              <Hash size={14} color="#64748B" />
              <Text style={styles.tableNumber}>{item.table_number}</Text>
            </View>
            <View style={styles.timeInfo}>
              <Text style={styles.orderDate}>{formatDate(item.created_at)}</Text>
              <Text style={styles.orderTime}>{formatTime(item.created_at)}</Text>
            </View>
          </View>
          <View style={[styles.statusBadge, { backgroundColor: status.bgColor }]}>
            <StatusIcon size={12} color={status.color} />
            <Text style={[styles.statusText, { color: status.color }]}>{status.label}</Text>
          </View>
        </View>

        <View style={styles.itemsList}>
          {item.items?.slice(0, 3).map((orderItem, index) => (
            <Text key={orderItem.id || index} style={styles.itemText}>
              {orderItem.quantity}x {orderItem.menu_item_name}
            </Text>
          ))}
          {item.items && item.items.length > 3 && (
            <Text style={styles.moreItems}>+{item.items.length - 3} more items</Text>
          )}
        </View>

        <View style={styles.orderFooter}>
          <Text style={styles.itemCount}>{itemCount} {itemCount === 1 ? 'item' : 'items'}</Text>
        </View>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Order History</Text>
      </View>

      {/* Stats Cards */}
      <View style={styles.statsContainer}>
        <View style={styles.statCard}>
          <View style={[styles.statIcon, { backgroundColor: '#DBEAFE' }]}>
            <ShoppingBag size={20} color="#3B82F6" />
          </View>
          <View>
            <Text style={styles.statValue}>{completedOrders.length}</Text>
            <Text style={styles.statLabel}>Orders</Text>
          </View>
        </View>

        <View style={styles.statCard}>
          <View style={[styles.statIcon, { backgroundColor: '#D1FAE5' }]}>
            <CheckCircle size={20} color="#10B981" />
          </View>
          <View>
            <Text style={styles.statValue}>{totalItems}</Text>
            <Text style={styles.statLabel}>Items Served</Text>
          </View>
        </View>
      </View>

      {/* Orders List */}
      <View style={styles.listHeader}>
        <Text style={styles.listTitle}>Recent Orders</Text>
      </View>

      {orders.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyTitle}>No order history</Text>
          <Text style={styles.emptySubtitle}>Completed orders will appear here</Text>
        </View>
      ) : (
        <FlatList
          data={orders}
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
  statsContainer: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    paddingVertical: 16,
    gap: 12,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  statCard: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
    padding: 12,
    borderRadius: 12,
    gap: 10,
  },
  statIcon: {
    width: 40,
    height: 40,
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
  },
  statValue: {
    fontSize: 16,
    fontWeight: '700',
    color: '#1E293B',
  },
  statLabel: {
    fontSize: 12,
    color: '#64748B',
  },
  listHeader: {
    paddingHorizontal: 20,
    paddingVertical: 16,
  },
  listTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1E293B',
  },
  listContent: {
    paddingHorizontal: 16,
    paddingBottom: 20,
    gap: 12,
  },
  orderCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 1,
  },
  orderHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  tableInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  tableBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F1F5F9',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 6,
    gap: 4,
  },
  tableNumber: {
    fontSize: 15,
    fontWeight: '600',
    color: '#64748B',
  },
  timeInfo: {
    flexDirection: 'row',
    gap: 8,
  },
  orderDate: {
    fontSize: 13,
    color: '#64748B',
    fontWeight: '500',
  },
  orderTime: {
    fontSize: 13,
    color: '#94A3B8',
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
    gap: 4,
  },
  statusText: {
    fontSize: 11,
    fontWeight: '600',
  },
  itemsList: {
    marginBottom: 12,
    gap: 4,
  },
  itemText: {
    fontSize: 14,
    color: '#475569',
  },
  moreItems: {
    fontSize: 13,
    color: '#94A3B8',
    fontStyle: 'italic',
  },
  orderFooter: {
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#E2E8F0',
  },
  itemCount: {
    fontSize: 14,
    color: '#64748B',
    fontWeight: '500',
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
