import { useEffect, useState } from 'react';
import { Stack, useSegments, Redirect } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useFrameworkReady } from '@/hooks/useFrameworkReady';
import { AuthProvider, useAuth } from '@/lib/AuthContext';
import { View, ActivityIndicator, StyleSheet } from 'react-native';
import { registerForPushNotifications } from '@/lib/notifications';

function RootLayoutNav() {
  const { user, isLoading } = useAuth();
  const segments = useSegments();

  // Register notifications when user logs in
  useEffect(() => {
    if (user) {
      registerForPushNotifications();
    }
  }, [user]);

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#0EA5E9" />
      </View>
    );
  }

  const inAuthGroup = segments[0] === 'login';

  // Redirect logic using Redirect component
  if (!user && !inAuthGroup) {
    return <Redirect href="/login" />;
  }

  if (user && inAuthGroup) {
    // Redirect based on role
    if (user.role === 'kitchen') {
      return <Redirect href="/(tabs)/journal" />;
    }
    return <Redirect href="/(tabs)" />;
  }

  return (
    <>
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="login" options={{ headerShown: false }} />
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen name="+not-found" />
      </Stack>
      <StatusBar style="auto" />
    </>
  );
}

export default function RootLayout() {
  useFrameworkReady();

  return (
    <AuthProvider>
      <RootLayoutNav />
    </AuthProvider>
  );
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
  },
});
