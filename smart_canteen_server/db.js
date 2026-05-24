const Database = require("better-sqlite3");
const path = require("path");

const db = new Database(path.resolve(__dirname, "canteenDB.db"));

function initializeDatabase() {

    db.exec(`

CREATE TABLE IF NOT EXISTS admins (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role TEXT DEFAULT 'ADMIN',
  created_at INTEGER
);

CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role TEXT DEFAULT 'student',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  avatar TEXT,
  google_id TEXT,
  points INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS foods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  price REAL NOT NULL,
  image TEXT,
  category TEXT,
  is_veg INTEGER DEFAULT 1,
  available INTEGER DEFAULT 1,
  created_at INTEGER,
  description TEXT
);

CREATE TABLE IF NOT EXISTS orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  total_amount REAL NOT NULL,
  status TEXT DEFAULT 'PLACED',
  created_at INTEGER DEFAULT (strftime('%s','now')),
  points_earned INTEGER DEFAULT 0,
  points_used INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS order_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  food_id INTEGER,
  name TEXT,
  price REAL,
  quantity INTEGER,
  FOREIGN KEY (order_id) REFERENCES orders(id)
);

CREATE TABLE IF NOT EXISTS food_reviews (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  food_id INTEGER NOT NULL,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at INTEGER DEFAULT (strftime('%s','now')),
  UNIQUE(user_id, food_id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (food_id) REFERENCES foods(id)
);

CREATE TABLE IF NOT EXISTS tokens (
  jti TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  issued_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  active INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_tokens_user ON tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_tokens_active ON tokens(active);

CREATE TABLE IF NOT EXISTS cart_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  food_id INTEGER NOT NULL,
  quantity INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, food_id)
);

CREATE TABLE IF NOT EXISTS favourites (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  food_id INTEGER NOT NULL,
  created_at INTEGER DEFAULT (strftime('%s','now')),
  UNIQUE(user_id, food_id)
);

CREATE TABLE IF NOT EXISTS offers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  subtitle TEXT,
  active INTEGER DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  expires_at INTEGER
);

CREATE TABLE IF NOT EXISTS point_settings (
  id INTEGER PRIMARY KEY,
  points_per_rupee REAL DEFAULT 0.1,
  max_discount_percent INTEGER DEFAULT 50
);

`);

    console.log("Database tables initialized");


    // Default MASTER admin
    db.prepare(`
INSERT OR IGNORE INTO admins (id, username, password, role, created_at)
VALUES (
  1,
  'master',
  '$2b$10$O64ojbSJTBuL/v2x/HsjhOwWO4aBRRgHIatFRkhoiD0tat3a1NcrO',
  'MASTER',
  strftime('%s','now')
)
`).run();


    // Default points settings
    db.prepare(`
INSERT OR IGNORE INTO point_settings (id, points_per_rupee, max_discount_percent)
VALUES (1, 0.1, 50)
`).run();

    console.log("Default data inserted");

}

initializeDatabase();

module.exports = db;