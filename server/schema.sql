CREATE DATABASE IF NOT EXISTS shoefit;
USE shoefit;

CREATE TABLE IF NOT EXISTS users_shoefit (
  uid VARCHAR(36) PRIMARY KEY,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  phone VARCHAR(40) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('customer', 'admin') NOT NULL DEFAULT 'customer',
  address VARCHAR(255) NOT NULL DEFAULT '',
  city VARCHAR(120) NOT NULL DEFAULT '',
  state VARCHAR(120) NOT NULL DEFAULT '',
  postcode VARCHAR(30) NOT NULL DEFAULT '',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products_shoefit (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  brand VARCHAR(120) NOT NULL,
  category VARCHAR(80) NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  rating DECIMAL(3, 1) NOT NULL DEFAULT 0,
  description TEXT NOT NULL,
  image_url TEXT NOT NULL,
  sizes JSON NOT NULL,
  material VARCHAR(120) NOT NULL,
  suitable_use VARCHAR(160) NOT NULL,
  stock INT NOT NULL DEFAULT 0,
  is_featured TINYINT(1) NOT NULL DEFAULT 0,
  is_new_arrival TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cart_items_shoefit (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(36) NOT NULL,
  shoe_id INT NOT NULL,
  selected_size INT NOT NULL,
  quantity INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_cart_size (user_id, shoe_id, selected_size),
  FOREIGN KEY (user_id) REFERENCES users_shoefit(uid) ON DELETE CASCADE,
  FOREIGN KEY (shoe_id) REFERENCES products_shoefit(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS favourites_shoefit (
  user_id VARCHAR(36) NOT NULL,
  product_id INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, product_id),
  FOREIGN KEY (user_id) REFERENCES users_shoefit(uid) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products_shoefit(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS orders_shoefit (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(36) NOT NULL,
  customer_name VARCHAR(120) NOT NULL,
  customer_phone VARCHAR(40) NOT NULL,
  delivery_address TEXT NOT NULL,
  subtotal DECIMAL(10, 2) NOT NULL,
  shipping_fee DECIMAL(10, 2) NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  payment_method VARCHAR(80) NOT NULL,
  payment_status VARCHAR(40) NOT NULL,
  stripe_payment_id VARCHAR(120) NOT NULL DEFAULT '',
  order_status VARCHAR(40) NOT NULL DEFAULT 'Processing',
  order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users_shoefit(uid) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS order_items_shoefit (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  shoe_id INT NOT NULL,
  name VARCHAR(160) NOT NULL,
  brand VARCHAR(120) NOT NULL,
  image_url TEXT NOT NULL,
  selected_size INT NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  quantity INT NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders_shoefit(id) ON DELETE CASCADE
);
