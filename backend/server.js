const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');

const app = express();
const PORT = 3001;

// Middleware
app.use(cors());
app.use(express.json());

// MySQL Connection Pool - initially without database to create it
let pool;

// Initialize database and tables
async function initializeDatabase() {
  try {
    // First connect without database to create it
    const tempConnection = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: '', // Default XAMPP MySQL has no password
    });

    // Create database if not exists
    await tempConnection.execute('CREATE DATABASE IF NOT EXISTS order_system');
    console.log('✅ Database "order_system" ready');
    await tempConnection.end();

    // Now create pool with database
    pool = mysql.createPool({
      host: 'localhost',
      user: 'root',
      password: '',
      database: 'order_system',
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0
    });

    // Create tables
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        name VARCHAR(100) NOT NULL,
        role ENUM('salesperson', 'kitchen') NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pool.execute(`
      CREATE TABLE IF NOT EXISTS menu_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        category VARCHAR(50) DEFAULT 'beverages',
        available BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pool.execute(`
      CREATE TABLE IF NOT EXISTS orders (
        id INT AUTO_INCREMENT PRIMARY KEY,
        table_number INT NOT NULL,
        status ENUM('pending', 'preparing', 'completed', 'cancelled') DEFAULT 'pending',
        notes TEXT,
        created_by INT,
        created_by_name VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
      )
    `);

    // Add created_by columns if they don't exist (for existing databases)
    try {
      await pool.execute(`ALTER TABLE orders ADD COLUMN created_by INT AFTER notes`);
      await pool.execute(`ALTER TABLE orders ADD COLUMN created_by_name VARCHAR(100) AFTER created_by`);
    } catch (e) {
      // Columns already exist, ignore error
    }

    await pool.execute(`
      CREATE TABLE IF NOT EXISTS order_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id INT NOT NULL,
        menu_item_id INT NOT NULL,
        menu_item_name VARCHAR(100) NOT NULL,
        quantity INT NOT NULL DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
      )
    `);

    // Insert default users if not exist
    const [users] = await pool.execute('SELECT COUNT(*) as count FROM users');
    if (users[0].count === 0) {
      await pool.execute(`
        INSERT INTO users (username, password, name, role) VALUES
        ('sales1', '1234', 'John Sales', 'salesperson'),
        ('sales2', '1234', 'Jane Sales', 'salesperson'),
        ('kitchen1', '1234', 'Chef Mike', 'kitchen'),
        ('kitchen2', '1234', 'Chef Sarah', 'kitchen')
      `);
      console.log('✅ Default users created');
    }

    // Insert default menu items if not exist
    const [items] = await pool.execute('SELECT COUNT(*) as count FROM menu_items');
    if (items[0].count === 0) {
      await pool.execute(`
        INSERT INTO menu_items (name, category, available) VALUES
        ('Water', 'beverages', TRUE),
        ('Tea', 'beverages', TRUE),
        ('Coffee', 'beverages', TRUE),
        ('Hot Chocolate', 'beverages', TRUE)
      `);
      console.log('✅ Default menu items created');
    }

    console.log('✅ All tables ready');
    return true;
  } catch (error) {
    console.error('❌ Database initialization failed:', error.message);
    console.log('⚠️  Make sure XAMPP MySQL is running!');
    return false;
  }
}

// Test database connection
app.get('/api/health', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    connection.release();
    res.json({ status: 'ok', message: 'Database connected' });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// ==================== USERS ====================

// Login
app.post('/api/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    const [rows] = await pool.execute(
      'SELECT id, username, name, role FROM users WHERE username = ? AND password = ?',
      [username, password]
    );
    
    if (rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    res.json({ user: rows[0] });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all users
app.get('/api/users', async (req, res) => {
  try {
    const [rows] = await pool.execute('SELECT id, username, name, role FROM users');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ==================== MENU ITEMS ====================

// Get all menu items
app.get('/api/menu', async (req, res) => {
  try {
    const [rows] = await pool.execute('SELECT * FROM menu_items WHERE available = 1');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ==================== ORDERS ====================

// Create new order
app.post('/api/orders', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    
    const { table_number, notes, items, created_by, created_by_name } = req.body;
    
    // Insert order with salesperson info
    const [orderResult] = await connection.execute(
      'INSERT INTO orders (table_number, status, notes, created_by, created_by_name) VALUES (?, ?, ?, ?, ?)',
      [table_number, 'pending', notes || null, created_by || null, created_by_name || null]
    );
    
    const orderId = orderResult.insertId;
    
    // Insert order items
    for (const item of items) {
      await connection.execute(
        'INSERT INTO order_items (order_id, menu_item_id, menu_item_name, quantity) VALUES (?, ?, ?, ?)',
        [orderId, item.menu_item_id, item.menu_item_name, item.quantity]
      );
    }
    
    await connection.commit();
    
    // Fetch the created order with items
    const [orders] = await connection.execute(
      'SELECT * FROM orders WHERE id = ?',
      [orderId]
    );
    const [orderItems] = await connection.execute(
      'SELECT * FROM order_items WHERE order_id = ?',
      [orderId]
    );
    
    res.status(201).json({ 
      ...orders[0], 
      items: orderItems 
    });
  } catch (error) {
    await connection.rollback();
    res.status(500).json({ error: error.message });
  } finally {
    connection.release();
  }
});

// Get all orders (with optional status filter)
app.get('/api/orders', async (req, res) => {
  try {
    const { status, created_by } = req.query;
    
    let query = 'SELECT * FROM orders';
    let params = [];
    let conditions = [];
    
    if (status) {
      if (status === 'active') {
        conditions.push('status IN (?, ?)');
        params.push('pending', 'preparing');
      } else if (status === 'history') {
        conditions.push('status IN (?, ?)');
        params.push('completed', 'cancelled');
      } else {
        conditions.push('status = ?');
        params.push(status);
      }
    }
    
    // Filter by salesperson
    if (created_by) {
      conditions.push('created_by = ?');
      params.push(created_by);
    }
    
    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    query += ' ORDER BY created_at DESC';
    
    const [orders] = await pool.execute(query, params);
    
    // Fetch items for each order
    for (let order of orders) {
      const [items] = await pool.execute(
        'SELECT * FROM order_items WHERE order_id = ?',
        [order.id]
      );
      order.items = items;
    }
    
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get single order
app.get('/api/orders/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const [orders] = await pool.execute('SELECT * FROM orders WHERE id = ?', [id]);
    
    if (orders.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }
    
    const [items] = await pool.execute(
      'SELECT * FROM order_items WHERE order_id = ?',
      [id]
    );
    
    res.json({ ...orders[0], items });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update order status
app.patch('/api/orders/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    const validStatuses = ['pending', 'preparing', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }
    
    await pool.execute(
      'UPDATE orders SET status = ?, updated_at = NOW() WHERE id = ?',
      [status, id]
    );
    
    const [orders] = await pool.execute('SELECT * FROM orders WHERE id = ?', [id]);
    const [items] = await pool.execute('SELECT * FROM order_items WHERE order_id = ?', [id]);
    
    res.json({ ...orders[0], items });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete order
app.delete('/api/orders/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    await pool.execute('DELETE FROM order_items WHERE order_id = ?', [id]);
    await pool.execute('DELETE FROM orders WHERE id = ?', [id]);
    
    res.json({ message: 'Order deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Start server
async function startServer() {
  const dbReady = await initializeDatabase();
  
  if (!dbReady) {
    console.log('\n⚠️  Running without database - make sure XAMPP MySQL is started!');
    console.log('   Open XAMPP Control Panel and click "Start" next to MySQL\n');
  }
  
  app.listen(PORT, () => {
    console.log(`\n🚀 Server running on http://localhost:${PORT}`);
    console.log(`📋 API Endpoints:`);
    console.log(`   GET  /api/health - Check database connection`);
    console.log(`   POST /api/login - User login`);
    console.log(`   GET  /api/menu - Get menu items`);
    console.log(`   GET  /api/orders - Get all orders`);
    console.log(`   POST /api/orders - Create new order`);
    console.log(`   PATCH /api/orders/:id/status - Update order status`);
  });
}

startServer();
