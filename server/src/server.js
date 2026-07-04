require('dotenv').config();

const bcrypt = require('bcryptjs');
const cors = require('cors');
const express = require('express');
const mysql = require('mysql2/promise');
const { randomUUID } = require('crypto');

const app = express();
const port = Number(process.env.PORT || 3000);
const databaseName = readEnvValue(['MYSQL_DATABASE', 'DB_DATABASE']) || 'shoefit';
const tableSuffix = readEnvValue(['MYSQL_TABLE_SUFFIX']) ?? '_shoefit';
const adminEmails = (readEnvValue(['ADMIN_EMAILS']) || 'aniq@mail.com')
  .split(',')
  .map((email) => email.trim().toLowerCase())
  .filter(Boolean);

const tableNames = {
  users: `users${tableSuffix}`,
  products: `products${tableSuffix}`,
  cartItems: `cart_items${tableSuffix}`,
  favourites: `favourites${tableSuffix}`,
  orders: `orders${tableSuffix}`,
  orderItems: `order_items${tableSuffix}`,
};

const tables = Object.fromEntries(
  Object.entries(tableNames).map(([key, value]) => [key, quoteIdentifier(value)]),
);

let pool;

function readEnvValue(names, { allowEmpty = false } = {}) {
  for (const name of names) {
    const value = process.env[name];
    if (value === undefined) {
      continue;
    }

    if (allowEmpty || String(value).trim() !== '') {
      return value;
    }
  }

  return undefined;
}

function parseDatabaseEndpoint(hostValue, fallbackPort) {
  const rawHost = String(hostValue || '').trim();
  if (!rawHost) {
    return {
      host: 'localhost',
      port: fallbackPort,
    };
  }

  const ipv6Match = rawHost.match(/^\[([^\]]+)\]:(\d+)$/);
  if (ipv6Match) {
    return {
      host: ipv6Match[1],
      port: Number(ipv6Match[2]),
    };
  }

  const colonCount = (rawHost.match(/:/g) || []).length;
  if (colonCount === 1) {
    const [host, maybePort] = rawHost.split(':');
    const parsedPort = Number(maybePort);
    if (host && Number.isInteger(parsedPort) && parsedPort > 0) {
      return {
        host,
        port: parsedPort,
      };
    }
  }

  return {
    host: rawHost,
    port: fallbackPort,
  };
}

function quoteIdentifier(value) {
  return `\`${String(value).replace(/`/g, '``')}\``;
}

async function initializeDatabaseConnection() {
  const configuredPort = Number(
    readEnvValue(['MYSQL_PORT', 'DB_PORT']) || 3306,
  );
  const databaseEndpoint = parseDatabaseEndpoint(
    readEnvValue(['MYSQL_HOST', 'DB_HOST']) || 'localhost',
    configuredPort,
  );
  const baseConfig = {
    host: databaseEndpoint.host,
    port: databaseEndpoint.port,
    user: readEnvValue(['MYSQL_USER', 'DB_USERNAME']) || 'root',
    password: readEnvValue(['MYSQL_PASSWORD', 'DB_PASSWORD'], { allowEmpty: true }) || '',
    waitForConnections: true,
    connectionLimit: 10,
    namedPlaceholders: true,
  };

  const bootstrap = await mysql.createConnection(baseConfig);
  await bootstrap.query(
    `CREATE DATABASE IF NOT EXISTS ${quoteIdentifier(databaseName)}`,
  );
  await bootstrap.end();

  pool = mysql.createPool({
    ...baseConfig,
    database: databaseName,
  });

  await migrateLegacyTables();
}

async function tableExists(tableName) {
  const [rows] = await pool.query(
    `SELECT TABLE_NAME
     FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?`,
    [databaseName, tableName],
  );
  return rows.length > 0;
}

async function migrateLegacyTables() {
  if (tableSuffix === '') {
    return;
  }

  const legacyTableNames = {
    users: 'users',
    products: 'products',
    cartItems: 'cart_items',
    favourites: 'favourites',
    orders: 'orders',
    orderItems: 'order_items',
  };

  const renamePairs = [];
  for (const [key, legacyName] of Object.entries(legacyTableNames)) {
    const nextName = tableNames[key];
    if (legacyName === nextName) {
      continue;
    }
    if ((await tableExists(legacyName)) && !(await tableExists(nextName))) {
      renamePairs.push([legacyName, nextName]);
    }
  }

  if (renamePairs.length === 0) {
    return;
  }

  const renameSql = renamePairs
    .map(([fromName, toName]) => `${quoteIdentifier(fromName)} TO ${quoteIdentifier(toName)}`)
    .join(', ');

  const connection = await pool.getConnection();
  try {
    await connection.query('SET FOREIGN_KEY_CHECKS = 0');
    await connection.query(`RENAME TABLE ${renameSql}`);
    console.log(
      `Renamed legacy ShoeFit tables with suffix "${tableSuffix}" for shared database hosting.`,
    );
  } catch (error) {
    console.warn('Could not rename legacy ShoeFit tables automatically.');
    console.warn(error.message);
  } finally {
    await connection.query('SET FOREIGN_KEY_CHECKS = 1');
    connection.release();
  }
}

app.use(cors());
app.use(express.json({ limit: '1mb' }));

function isAdminEmail(email) {
  return adminEmails.includes(String(email || '').trim().toLowerCase());
}

function requireFields(body, fields) {
  for (const field of fields) {
    if (body[field] === undefined || body[field] === null || body[field] === '') {
      const error = new Error(`${field} is required.`);
      error.status = 400;
      throw error;
    }
  }
}

function iso(value) {
  if (!value) return new Date().toISOString();
  if (value instanceof Date) return value.toISOString();
  return new Date(value).toISOString();
}

function readSizes(raw) {
  if (Array.isArray(raw)) return raw.map(Number);
  if (typeof raw === 'string') {
    try {
      return JSON.parse(raw).map(Number);
    } catch (_) {
      return [];
    }
  }
  return [];
}

function mapUser(row) {
  return {
    uid: row.uid,
    fullName: row.full_name,
    email: row.email,
    phone: row.phone,
    role: row.role,
    address: row.address || '',
    city: row.city || '',
    state: row.state || '',
    postcode: row.postcode || '',
    createdAt: iso(row.created_at),
  };
}

function mapProduct(row) {
  return {
    id: String(row.id),
    name: row.name,
    brand: row.brand,
    category: row.category,
    price: Number(row.price),
    rating: Number(row.rating),
    description: row.description,
    imageUrl: row.image_url,
    sizes: readSizes(row.sizes),
    material: row.material,
    suitableUse: row.suitable_use,
    stock: Number(row.stock),
    isFeatured: Boolean(row.is_featured),
    isNewArrival: Boolean(row.is_new_arrival),
    createdAt: iso(row.created_at),
  };
}

function mapCartItem(row) {
  return {
    id: String(row.id),
    shoeId: String(row.shoe_id),
    name: row.name,
    brand: row.brand,
    imageUrl: row.image_url,
    selectedSize: Number(row.selected_size),
    price: Number(row.price),
    quantity: Number(row.quantity),
  };
}

function mapOrder(row, items = []) {
  return {
    id: String(row.id),
    orderId: String(row.id),
    userId: row.user_id,
    customerName: row.customer_name,
    customerPhone: row.customer_phone,
    deliveryAddress: row.delivery_address,
    items,
    subtotal: Number(row.subtotal),
    shippingFee: Number(row.shipping_fee),
    totalPrice: Number(row.total_price),
    paymentMethod: row.payment_method,
    paymentStatus: row.payment_status,
    stripePaymentId: row.stripe_payment_id || '',
    orderStatus: row.order_status,
    orderDate: iso(row.order_date),
  };
}

async function ensureSchema() {
  const statements = [
    `CREATE TABLE IF NOT EXISTS ${tables.users} (
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
    )`,
    `CREATE TABLE IF NOT EXISTS ${tables.products} (
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
    )`,
    `CREATE TABLE IF NOT EXISTS ${tables.cartItems} (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id VARCHAR(36) NOT NULL,
      shoe_id INT NOT NULL,
      selected_size INT NOT NULL,
      quantity INT NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE KEY unique_cart_size (user_id, shoe_id, selected_size),
      FOREIGN KEY (user_id) REFERENCES ${tables.users}(uid) ON DELETE CASCADE,
      FOREIGN KEY (shoe_id) REFERENCES ${tables.products}(id) ON DELETE CASCADE
    )`,
    `CREATE TABLE IF NOT EXISTS ${tables.favourites} (
      user_id VARCHAR(36) NOT NULL,
      product_id INT NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (user_id, product_id),
      FOREIGN KEY (user_id) REFERENCES ${tables.users}(uid) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES ${tables.products}(id) ON DELETE CASCADE
    )`,
    `CREATE TABLE IF NOT EXISTS ${tables.orders} (
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
      FOREIGN KEY (user_id) REFERENCES ${tables.users}(uid) ON DELETE CASCADE
    )`,
    `CREATE TABLE IF NOT EXISTS ${tables.orderItems} (
      id INT AUTO_INCREMENT PRIMARY KEY,
      order_id INT NOT NULL,
      shoe_id INT NOT NULL,
      name VARCHAR(160) NOT NULL,
      brand VARCHAR(120) NOT NULL,
      image_url TEXT NOT NULL,
      selected_size INT NOT NULL,
      price DECIMAL(10, 2) NOT NULL,
      quantity INT NOT NULL,
      FOREIGN KEY (order_id) REFERENCES ${tables.orders}(id) ON DELETE CASCADE
    )`,
  ];

  for (const statement of statements) {
    await pool.query(statement);
  }
}

async function ensureDemoAdmins() {
  for (const email of adminEmails) {
    const [existing] = await pool.query(
      `SELECT uid FROM ${tables.users} WHERE email = ?`,
      [email],
    );
    if (existing.length > 0) {
      await pool.query(`UPDATE ${tables.users} SET role = ? WHERE email = ?`, [
        'admin',
        email,
      ]);
      continue;
    }

    await pool.query(
      `INSERT INTO ${tables.users}
        (uid, full_name, email, phone, password_hash, role)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        randomUUID(),
        'Demo Admin',
        email,
        '0123456789',
        await bcrypt.hash('admin123', 10),
        'admin',
      ],
    );
  }
}

async function getOrders(whereSql = '', params = []) {
  const [orderRows] = await pool.query(
    `SELECT * FROM ${tables.orders} ${whereSql} ORDER BY order_date DESC`,
    params,
  );

  if (orderRows.length === 0) return [];

  const orderIds = orderRows.map((row) => row.id);
  const [itemRows] = await pool.query(
    `SELECT * FROM ${tables.orderItems} WHERE order_id IN (?) ORDER BY id ASC`,
    [orderIds],
  );
  const itemsByOrder = new Map();
  for (const item of itemRows) {
    const list = itemsByOrder.get(item.order_id) || [];
    list.push({
      id: String(item.id),
      shoeId: String(item.shoe_id),
      name: item.name,
      brand: item.brand,
      imageUrl: item.image_url,
      selectedSize: Number(item.selected_size),
      price: Number(item.price),
      quantity: Number(item.quantity),
    });
    itemsByOrder.set(item.order_id, list);
  }

  return orderRows.map((row) => mapOrder(row, itemsByOrder.get(row.id) || []));
}

app.get('/api/health', async (_req, res) => {
  await pool.query('SELECT 1');
  res.json({ ok: true });
});

app.post('/api/auth/register', async (req, res) => {
  requireFields(req.body, ['fullName', 'email', 'phone', 'password']);
  const uid = randomUUID();
  const email = String(req.body.email).trim().toLowerCase();
  const passwordHash = await bcrypt.hash(String(req.body.password), 10);
  const role = isAdminEmail(email) ? 'admin' : 'customer';

  try {
    await pool.query(
      `INSERT INTO ${tables.users}
        (uid, full_name, email, phone, password_hash, role)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [uid, req.body.fullName, email, req.body.phone, passwordHash, role],
    );
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      error.status = 409;
      error.message = 'That email is already registered.';
    }
    throw error;
  }

  const [rows] = await pool.query(`SELECT * FROM ${tables.users} WHERE uid = ?`, [
    uid,
  ]);
  res.status(201).json({ user: mapUser(rows[0]) });
});

app.post('/api/auth/login', async (req, res) => {
  requireFields(req.body, ['email', 'password']);
  const email = String(req.body.email).trim().toLowerCase();
  const [rows] = await pool.query(
    `SELECT * FROM ${tables.users} WHERE email = ?`,
    [email],
  );
  if (rows.length === 0) {
    const error = new Error('Incorrect email or password.');
    error.status = 401;
    throw error;
  }

  const user = rows[0];
  const matches = await bcrypt.compare(String(req.body.password), user.password_hash);
  if (!matches) {
    const error = new Error('Incorrect email or password.');
    error.status = 401;
    throw error;
  }

  res.json({ user: mapUser(user) });
});

app.get('/api/users/:uid', async (req, res) => {
  const [rows] = await pool.query(
    `SELECT * FROM ${tables.users} WHERE uid = ?`,
    [req.params.uid],
  );
  if (rows.length === 0) {
    const error = new Error('User not found.');
    error.status = 404;
    throw error;
  }
  res.json({ user: mapUser(rows[0]) });
});

app.put('/api/users/:uid', async (req, res) => {
  requireFields(req.body, ['fullName', 'phone', 'address', 'city', 'state', 'postcode']);
  await pool.query(
    `UPDATE ${tables.users}
     SET full_name = ?, phone = ?, address = ?, city = ?, state = ?, postcode = ?
     WHERE uid = ?`,
    [
      req.body.fullName,
      req.body.phone,
      req.body.address,
      req.body.city,
      req.body.state,
      req.body.postcode,
      req.params.uid,
    ],
  );
  const [rows] = await pool.query(
    `SELECT * FROM ${tables.users} WHERE uid = ?`,
    [req.params.uid],
  );
  res.json({ user: mapUser(rows[0]) });
});

app.get('/api/products', async (_req, res) => {
  const [rows] = await pool.query(
    `SELECT * FROM ${tables.products} ORDER BY created_at DESC`,
  );
  res.json({ products: rows.map(mapProduct) });
});

app.get('/api/products/:id', async (req, res) => {
  const [rows] = await pool.query(
    `SELECT * FROM ${tables.products} WHERE id = ?`,
    [req.params.id],
  );
  if (rows.length === 0) {
    const error = new Error('Product not found.');
    error.status = 404;
    throw error;
  }
  res.json({ product: mapProduct(rows[0]) });
});

app.post('/api/products/seed', async (_req, res) => {
  const [existing] = await pool.query(`SELECT id FROM ${tables.products} LIMIT 1`);
  if (existing.length > 0) {
    res.json({ inserted: 0 });
    return;
  }

  for (const product of sampleProducts) {
    await insertProduct(product);
  }
  res.status(201).json({ inserted: sampleProducts.length });
});

app.post('/api/products', async (req, res) => {
  const result = await insertProduct(req.body);
  const [rows] = await pool.query(
    `SELECT * FROM ${tables.products} WHERE id = ?`,
    [result.insertId],
  );
  res.status(201).json({ product: mapProduct(rows[0]) });
});

app.put('/api/products/:id', async (req, res) => {
  requireProduct(req.body);
  await pool.query(
    `UPDATE ${tables.products}
     SET name = ?, brand = ?, category = ?, price = ?, rating = ?, description = ?,
         image_url = ?, sizes = ?, material = ?, suitable_use = ?, stock = ?,
         is_featured = ?, is_new_arrival = ?
     WHERE id = ?`,
    [
      req.body.name,
      req.body.brand,
      req.body.category,
      Number(req.body.price),
      Number(req.body.rating),
      req.body.description,
      req.body.imageUrl,
      JSON.stringify(req.body.sizes || []),
      req.body.material,
      req.body.suitableUse,
      Number(req.body.stock),
      req.body.isFeatured ? 1 : 0,
      req.body.isNewArrival ? 1 : 0,
      req.params.id,
    ],
  );
  const [rows] = await pool.query(
    `SELECT * FROM ${tables.products} WHERE id = ?`,
    [req.params.id],
  );
  res.json({ product: mapProduct(rows[0]) });
});

app.delete('/api/products/:id', async (req, res) => {
  await pool.query(`DELETE FROM ${tables.products} WHERE id = ?`, [req.params.id]);
  res.status(204).send();
});

app.get('/api/users/:uid/cart', async (req, res) => {
  res.json({ items: await getCartItems(req.params.uid) });
});

app.post('/api/users/:uid/cart', async (req, res) => {
  requireFields(req.body, ['shoeId', 'selectedSize', 'quantity']);
  const [products] = await pool.query(
    `SELECT * FROM ${tables.products} WHERE id = ?`,
    [req.body.shoeId],
  );
  if (products.length === 0) {
    const error = new Error('Product not found.');
    error.status = 404;
    throw error;
  }
  const product = products[0];
  const quantity = Number(req.body.quantity);
  if (quantity > Number(product.stock)) {
    const error = new Error(`Only ${product.stock} pair(s) are available.`);
    error.status = 400;
    throw error;
  }

  await pool.query(
    `INSERT INTO ${tables.cartItems} (user_id, shoe_id, selected_size, quantity)
     VALUES (?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity)`,
    [req.params.uid, req.body.shoeId, req.body.selectedSize, quantity],
  );
  res.status(201).json({ items: await getCartItems(req.params.uid) });
});

app.patch('/api/users/:uid/cart/:cartItemId', async (req, res) => {
  requireFields(req.body, ['quantity']);
  await pool.query(
    `UPDATE ${tables.cartItems} SET quantity = ? WHERE user_id = ? AND id = ?`,
    [Number(req.body.quantity), req.params.uid, req.params.cartItemId],
  );
  res.json({ items: await getCartItems(req.params.uid) });
});

app.delete('/api/users/:uid/cart', async (req, res) => {
  await pool.query(`DELETE FROM ${tables.cartItems} WHERE user_id = ?`, [
    req.params.uid,
  ]);
  res.status(204).send();
});

app.delete('/api/users/:uid/cart/:cartItemId', async (req, res) => {
  await pool.query(
    `DELETE FROM ${tables.cartItems} WHERE user_id = ? AND id = ?`,
    [req.params.uid, req.params.cartItemId],
  );
  res.status(204).send();
});

app.get('/api/users/:uid/favourites', async (req, res) => {
  const [rows] = await pool.query(
    `SELECT product_id FROM ${tables.favourites} WHERE user_id = ?`,
    [req.params.uid],
  );
  res.json({ productIds: rows.map((row) => String(row.product_id)) });
});

app.put('/api/users/:uid/favourites/:productId', async (req, res) => {
  await pool.query(
    `INSERT IGNORE INTO ${tables.favourites} (user_id, product_id) VALUES (?, ?)`,
    [req.params.uid, req.params.productId],
  );
  res.status(204).send();
});

app.delete('/api/users/:uid/favourites/:productId', async (req, res) => {
  await pool.query(
    `DELETE FROM ${tables.favourites} WHERE user_id = ? AND product_id = ?`,
    [req.params.uid, req.params.productId],
  );
  res.status(204).send();
});

app.get('/api/users/:uid/orders', async (req, res) => {
  res.json({
    orders: await getOrders('WHERE user_id = ?', [req.params.uid]),
  });
});

app.get('/api/orders', async (_req, res) => {
  res.json({ orders: await getOrders() });
});

app.patch('/api/orders/:id', async (req, res) => {
  requireFields(req.body, ['orderStatus']);
  await pool.query(`UPDATE ${tables.orders} SET order_status = ? WHERE id = ?`, [
    req.body.orderStatus,
    req.params.id,
  ]);
  res.json({ orders: await getOrders() });
});

app.post('/api/checkout', async (req, res) => {
  requireFields(req.body, ['userId', 'customerName', 'customerPhone', 'deliveryAddress']);
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [cartRows] = await connection.query(
      `SELECT ci.*, p.name, p.brand, p.image_url, p.price, p.stock
       FROM ${tables.cartItems} ci
       JOIN ${tables.products} p ON p.id = ci.shoe_id
       WHERE ci.user_id = ?
       FOR UPDATE`,
      [req.body.userId],
    );

    if (cartRows.length === 0) {
      const error = new Error('Your cart is empty.');
      error.status = 400;
      throw error;
    }

    let subtotal = 0;
    for (const item of cartRows) {
      if (Number(item.quantity) > Number(item.stock)) {
        const error = new Error(`Only ${item.stock} pair(s) of ${item.name} are available.`);
        error.status = 400;
        throw error;
      }
      subtotal += Number(item.price) * Number(item.quantity);
      await connection.query(
        `UPDATE ${tables.products} SET stock = stock - ? WHERE id = ?`,
        [item.quantity, item.shoe_id],
      );
    }

    const shippingFee = 15;
    const totalPrice = subtotal + shippingFee;
    const [orderResult] = await connection.query(
      `INSERT INTO ${tables.orders}
       (user_id, customer_name, customer_phone, delivery_address, subtotal,
        shipping_fee, total_price, payment_method, payment_status, stripe_payment_id,
        order_status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.body.userId,
        req.body.customerName,
        req.body.customerPhone,
        req.body.deliveryAddress,
        subtotal,
        shippingFee,
        totalPrice,
        req.body.paymentMethod || 'Demo card',
        req.body.paymentStatus || 'paid',
        `demo_${Date.now()}`,
        'Processing',
      ],
    );

    for (const item of cartRows) {
      await connection.query(
        `INSERT INTO ${tables.orderItems}
         (order_id, shoe_id, name, brand, image_url, selected_size, price, quantity)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          orderResult.insertId,
          item.shoe_id,
          item.name,
          item.brand,
          item.image_url,
          item.selected_size,
          item.price,
          item.quantity,
        ],
      );
    }

    await connection.query(`DELETE FROM ${tables.cartItems} WHERE user_id = ?`, [
      req.body.userId,
    ]);
    await connection.commit();

    const orders = await getOrders('WHERE id = ?', [orderResult.insertId]);
    res.status(201).json({ order: orders[0] });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
});

app.get('/api/stats', async (_req, res) => {
  const [[products]] = await pool.query(
    `SELECT COUNT(*) AS count FROM ${tables.products}`,
  );
  const [[users]] = await pool.query(
    `SELECT COUNT(*) AS count FROM ${tables.users}`,
  );
  const [[orders]] = await pool.query(
    `SELECT COUNT(*) AS count FROM ${tables.orders}`,
  );
  const [[pending]] = await pool.query(
    `SELECT COUNT(*) AS count FROM ${tables.orders} WHERE order_status = 'Processing'`,
  );
  const [[sales]] = await pool.query(
    `SELECT COALESCE(SUM(total_price), 0) AS total FROM ${tables.orders} WHERE payment_status = 'paid'`,
  );

  res.json({
    totalProducts: Number(products.count),
    totalUsers: Number(users.count),
    totalOrders: Number(orders.count),
    pendingOrders: Number(pending.count),
    totalSales: Number(sales.total),
  });
});

async function getCartItems(userId) {
  const [rows] = await pool.query(
    `SELECT ci.id, ci.shoe_id, ci.selected_size, ci.quantity,
            p.name, p.brand, p.image_url, p.price
     FROM ${tables.cartItems} ci
     JOIN ${tables.products} p ON p.id = ci.shoe_id
     WHERE ci.user_id = ?
     ORDER BY ci.created_at DESC`,
    [userId],
  );
  return rows.map(mapCartItem);
}

function requireProduct(product) {
  requireFields(product, [
    'name',
    'brand',
    'category',
    'price',
    'rating',
    'description',
    'imageUrl',
    'sizes',
    'material',
    'suitableUse',
    'stock',
  ]);
}

async function insertProduct(product) {
  requireProduct(product);
  const [result] = await pool.query(
    `INSERT INTO ${tables.products}
     (name, brand, category, price, rating, description, image_url, sizes,
      material, suitable_use, stock, is_featured, is_new_arrival)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      product.name,
      product.brand,
      product.category,
      Number(product.price),
      Number(product.rating),
      product.description,
      product.imageUrl,
      JSON.stringify(product.sizes || []),
      product.material,
      product.suitableUse,
      Number(product.stock),
      product.isFeatured ? 1 : 0,
      product.isNewArrival ? 1 : 0,
    ],
  );
  return result;
}

app.use((error, _req, res, _next) => {
  const status = error.status || 500;
  if (status >= 500) {
    console.error(error);
  }
  res.status(status).json({
    message: error.message || 'Local MySQL API error.',
  });
});

const sampleProducts = [
  {
    name: 'Velocity One',
    brand: 'Astra',
    category: 'Running',
    price: 399,
    rating: 4.8,
    description: 'Featherlight running shoes with responsive foam for daily tempo sessions.',
    imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1200&q=80',
    sizes: [38, 39, 40, 41, 42, 43],
    material: 'Engineered mesh',
    suitableUse: 'Road running',
    stock: 24,
    isFeatured: true,
    isNewArrival: true,
  },
  {
    name: 'Court Pulse',
    brand: 'Northline',
    category: 'Sneakers',
    price: 459,
    rating: 4.7,
    description: 'Premium leather low-top sneaker with a clean silhouette for everyday wear.',
    imageUrl: 'https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?auto=format&fit=crop&w=1200&q=80',
    sizes: [39, 40, 41, 42, 43, 44],
    material: 'Full-grain leather',
    suitableUse: 'Lifestyle',
    stock: 16,
    isFeatured: true,
    isNewArrival: false,
  },
  {
    name: 'Metro Ease',
    brand: 'Orbyt',
    category: 'Casual',
    price: 289,
    rating: 4.4,
    description: 'Soft knit casual shoe that balances airy comfort with minimalist style.',
    imageUrl: 'https://images.unsplash.com/photo-1543508282-6319a3e2621f?auto=format&fit=crop&w=1200&q=80',
    sizes: [37, 38, 39, 40, 41],
    material: 'Knit textile',
    suitableUse: 'Daily commuting',
    stock: 31,
    isFeatured: false,
    isNewArrival: true,
  },
  {
    name: 'Boardwalk Classic',
    brand: 'Elm & Edge',
    category: 'Casual',
    price: 319,
    rating: 4.3,
    description: 'Relaxed canvas sneaker designed for all-day comfort and easy styling.',
    imageUrl: 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?auto=format&fit=crop&w=1200&q=80',
    sizes: [38, 39, 40, 41, 42],
    material: 'Canvas upper',
    suitableUse: 'Weekend casual',
    stock: 22,
    isFeatured: false,
    isNewArrival: false,
  },
  {
    name: 'Stride Pro',
    brand: 'Astra',
    category: 'Sports',
    price: 499,
    rating: 4.9,
    description: 'High-stability training shoe built for agility drills, gym work, and quick cuts.',
    imageUrl: 'https://images.unsplash.com/photo-1514989940723-e8e51635b782?auto=format&fit=crop&w=1200&q=80',
    sizes: [40, 41, 42, 43, 44],
    material: 'TPU support cage',
    suitableUse: 'Cross training',
    stock: 13,
    isFeatured: true,
    isNewArrival: true,
  },
  {
    name: 'Monarch Derby',
    brand: 'Noir Atelier',
    category: 'Formal',
    price: 549,
    rating: 4.6,
    description: 'Elegant derby shoe with polished finish for business and evening occasions.',
    imageUrl: 'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?auto=format&fit=crop&w=1200&q=80',
    sizes: [40, 41, 42, 43],
    material: 'Polished calfskin',
    suitableUse: 'Formal events',
    stock: 10,
    isFeatured: true,
    isNewArrival: false,
  },
];

initializeDatabaseConnection()
  .then(ensureSchema)
  .then(ensureDemoAdmins)
  .then(() => {
    app.listen(port, () => {
      console.log(`ShoeFit MySQL API listening on port ${port}.`);
    });
  })
  .catch((error) => {
    console.error('Failed to start ShoeFit MySQL API.');
    console.error(error);
    process.exit(1);
  });
