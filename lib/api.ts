import { Platform } from 'react-native';

// API Configuration and Service
// Laravel backend on Hostinger VPS
const API_BASE_URL = 'https://cofee.cameralkstore.com/api';

console.log('API URL:', API_BASE_URL);

export const api = {
  // Health check
  async healthCheck() {
    const response = await fetch(`${API_BASE_URL}/health`);
    return response.json();
  },

  // Login
  async login(username: string, password: string) {
    const response = await fetch(`${API_BASE_URL}/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password }),
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Login failed');
    }
    
    return response.json();
  },

  // Get menu items
  async getMenu() {
    const response = await fetch(`${API_BASE_URL}/menu`);
    if (!response.ok) throw new Error('Failed to fetch menu');
    return response.json();
  },

  // Create order
  async createOrder(order: {
    table_number: number;
    notes?: string;
    items: Array<{ menu_item_id: number; menu_item_name: string; quantity: number }>;
    created_by?: number;
    created_by_name?: string;
  }) {
    const response = await fetch(`${API_BASE_URL}/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(order),
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to create order');
    }
    
    return response.json();
  },

  // Get orders (with optional filter and user filter)
  async getOrders(filter?: 'active' | 'history' | 'pending' | 'preparing' | 'completed', userId?: number) {
    let url = `${API_BASE_URL}/orders`;
    const params = new URLSearchParams();
    
    if (filter) params.append('status', filter);
    if (userId) params.append('created_by', userId.toString());
    
    if (params.toString()) {
      url += '?' + params.toString();
    }
    
    const response = await fetch(url);
    if (!response.ok) throw new Error('Failed to fetch orders');
    return response.json();
  },

  // Update order status
  async updateOrderStatus(orderId: number, status: 'pending' | 'preparing' | 'completed' | 'cancelled') {
    const response = await fetch(`${API_BASE_URL}/orders/${orderId}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status }),
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to update order');
    }
    
    return response.json();
  },

  // Delete order
  async deleteOrder(orderId: number) {
    const response = await fetch(`${API_BASE_URL}/orders/${orderId}`, {
      method: 'DELETE',
    });
    
    if (!response.ok) throw new Error('Failed to delete order');
    return response.json();
  },
};

export default api;
