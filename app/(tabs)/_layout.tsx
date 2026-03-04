import { Tabs, useRouter, useSegments } from 'expo-router';
import { ClipboardList, ChefHat, History, LogOut } from 'lucide-react-native';
import { useAuth } from '@/lib/AuthContext';
import { TouchableOpacity, Alert } from 'react-native';
import { useEffect } from 'react';

export default function TabLayout() {
  const { user, logout } = useAuth();
  const router = useRouter();
  const segments = useSegments();
  const isSalesperson = user?.role === 'salesperson';
  const isKitchen = user?.role === 'kitchen';

  // Redirect to correct initial tab based on role
  useEffect(() => {
    if (!user) return;
    
    const currentTab = segments[1]; // e.g., 'index', 'journal', 'insights'
    
    // Kitchen user trying to access sales tab
    if (isKitchen && currentTab === 'index') {
      router.replace('/(tabs)/journal');
    }
    // Salesperson trying to access kitchen tab or history
    if (isSalesperson && (currentTab === 'journal' || currentTab === 'insights')) {
      router.replace('/(tabs)/index');
    }
  }, [user, segments]);

  const handleLogout = () => {
    Alert.alert(
      'Logout',
      'Are you sure you want to logout?',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Logout', style: 'destructive', onPress: logout },
      ]
    );
  };

  return (
    <Tabs
      screenOptions={{
        headerShown: true,
        headerTitle: `Hi, ${user?.name || 'User'}`,
        headerTitleStyle: {
          fontSize: 16,
          fontWeight: '600',
          color: '#1E293B',
        },
        headerRight: () => (
          <TouchableOpacity onPress={handleLogout} style={{ marginRight: 16 }}>
            <LogOut size={22} color="#EF4444" />
          </TouchableOpacity>
        ),
        tabBarActiveTintColor: '#0EA5E9',
        tabBarInactiveTintColor: '#94A3B8',
        tabBarStyle: {
          backgroundColor: '#FFFFFF',
          borderTopWidth: 1,
          borderTopColor: '#E2E8F0',
          paddingTop: 8,
          paddingBottom: 8,
          height: 70,
        },
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '600',
          marginTop: 4,
        },
      }}>
      {/* New Order - Only for Salesperson */}
      <Tabs.Screen
        name="index"
        options={{
          title: 'New Order',
          href: isSalesperson ? undefined : null,
          tabBarIcon: ({ size, color }) => (
            <ClipboardList size={size} color={color} strokeWidth={2} />
          ),
        }}
      />
      {/* Kitchen - Only for Kitchen staff */}
      <Tabs.Screen
        name="journal"
        options={{
          title: 'Kitchen',
          href: isKitchen ? undefined : null,
          tabBarIcon: ({ size, color }) => (
            <ChefHat size={size} color={color} strokeWidth={2} />
          ),
        }}
      />
      {/* History - Only for Kitchen staff */}
      <Tabs.Screen
        name="insights"
        options={{
          title: 'History',
          href: isKitchen ? undefined : null,
          tabBarIcon: ({ size, color }) => (
            <History size={size} color={color} strokeWidth={2} />
          ),
        }}
      />
    </Tabs>
  );
}
