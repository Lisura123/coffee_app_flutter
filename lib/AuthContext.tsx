import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { User, DEFAULT_USERS, DEFAULT_PASSWORDS } from './supabase';
import api from './api';

type AuthContextType = {
  user: User | null;
  isLoading: boolean;
  login: (username: string, password: string) => Promise<{ success: boolean; error?: string }>;
  logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const AUTH_STORAGE_KEY = '@order_app_user';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Load saved user on app start
  useEffect(() => {
    loadSavedUser();
  }, []);

  const loadSavedUser = async () => {
    try {
      const savedUser = await AsyncStorage.getItem(AUTH_STORAGE_KEY);
      if (savedUser) {
        setUser(JSON.parse(savedUser));
      }
    } catch (error) {
      console.error('Error loading saved user:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (username: string, password: string): Promise<{ success: boolean; error?: string }> => {
    const trimmedUsername = username.trim().toLowerCase();
    const trimmedPassword = password.trim();

    try {
      // Try MySQL API first
      const result = await api.login(trimmedUsername, trimmedPassword);
      const foundUser = result.user;
      
      await AsyncStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(foundUser));
      setUser(foundUser);
      return { success: true };
    } catch (apiError) {
      console.log('API login failed, using fallback:', apiError);
      
      // Fallback to local users
      const foundUser = DEFAULT_USERS.find(u => u.username.toLowerCase() === trimmedUsername);
      
      if (!foundUser) {
        return { success: false, error: 'User not found' };
      }

      const correctPassword = DEFAULT_PASSWORDS[foundUser.username];
      if (trimmedPassword !== correctPassword) {
        return { success: false, error: 'Incorrect password' };
      }

      try {
        await AsyncStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(foundUser));
        setUser(foundUser);
        return { success: true };
      } catch (error) {
        console.error('Error saving user:', error);
        return { success: false, error: 'Failed to save login' };
      }
    }
  };

  const logout = async () => {
    try {
      await AsyncStorage.removeItem(AUTH_STORAGE_KEY);
      setUser(null);
    } catch (error) {
      console.error('Error during logout:', error);
    }
  };

  return (
    <AuthContext.Provider value={{ user, isLoading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
