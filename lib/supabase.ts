import { createClient } from '@supabase/supabase-js';
import 'react-native-url-polyfill/auto';

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// User roles
export type UserRole = 'salesperson' | 'kitchen';

// User type
export type User = {
  id: string;
  username: string;
  name: string;
  role: UserRole;
};

// Default users for demo (in production, use Supabase Auth)
export const DEFAULT_USERS: User[] = [
  { id: '1', username: 'sales1', name: 'John Sales', role: 'salesperson' },
  { id: '2', username: 'sales2', name: 'Jane Sales', role: 'salesperson' },
  { id: '3', username: 'kitchen1', name: 'Chef Mike', role: 'kitchen' },
  { id: '4', username: 'kitchen2', name: 'Chef Sarah', role: 'kitchen' },
];

// Default passwords (demo only - in production use proper auth)
export const DEFAULT_PASSWORDS: Record<string, string> = {
  'sales1': '1234',
  'sales2': '1234',
  'kitchen1': '1234',
  'kitchen2': '1234',
};

// Menu Items
export type MenuItem = {
  id: string;
  name: string;
  category: 'beverages';
  available: boolean;
};

// Order Item (items in an order)
export type OrderItem = {
  id: string;
  order_id: string;
  menu_item_id: string;
  menu_item_name: string;
  quantity: number;
};

// Order
export type Order = {
  id: string;
  table_number: number;
  status: 'pending' | 'preparing' | 'completed' | 'cancelled';
  notes?: string;
  created_at: string;
  updated_at: string;
  items?: OrderItem[];
};

// Default menu items (used if no database)
export const DEFAULT_MENU_ITEMS: MenuItem[] = [
  { id: '1', name: 'Water', category: 'beverages', available: true },
  { id: '2', name: 'Tea', category: 'beverages', available: true },
  { id: '3', name: 'Coffee', category: 'beverages', available: true },
  { id: '4', name: 'Hot Chocolate', category: 'beverages', available: true },
];
