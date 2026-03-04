-- MySQL Database Setup for Order System
-- Run this in phpMyAdmin (XAMPP)

-- Create Database
CREATE DATABASE IF NOT EXISTS order_system;
USE order_system;

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    role ENUM('salesperson', 'kitchen') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Menu Items Table
CREATE TABLE IF NOT EXISTS menu_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) DEFAULT 'beverages',
    available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders Table
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    table_number INT NOT NULL,
    status ENUM('pending', 'preparing', 'completed', 'cancelled') DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Order Items Table
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    menu_item_id INT NOT NULL,
    menu_item_name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (menu_item_id) REFERENCES menu_items(id)
);

-- Insert Default Users
INSERT INTO users (username, password, name, role) VALUES
('sales1', '1234', 'John Sales', 'salesperson'),
('sales2', '1234', 'Jane Sales', 'salesperson'),
('kitchen1', '1234', 'Chef Mike', 'kitchen'),
('kitchen2', '1234', 'Chef Sarah', 'kitchen');

-- Insert Menu Items (Water, Tea, Coffee, Hot Chocolate only)
INSERT INTO menu_items (name, category, available) VALUES
('Water', 'beverages', TRUE),
('Tea', 'beverages', TRUE),
('Coffee', 'beverages', TRUE),
('Hot Chocolate', 'beverages', TRUE);

-- Show created tables
SHOW TABLES;

-- Verify data
SELECT * FROM users;
SELECT * FROM menu_items;
