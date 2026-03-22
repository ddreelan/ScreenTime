'use strict';

const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');
const logger = require('./logger');

const DB_PATH = process.env.DB_PATH || path.join(__dirname, '../../data/screentime.db');

// Ensure data directory exists
const dataDir = path.dirname(DB_PATH);
if (dataDir !== '.' && !fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

let db;

function getDb() {
  if (!db) {
    db = new sqlite3.Database(DB_PATH, (err) => {
      if (err) {
        logger.error('Database connection error:', err);
        throw err;
      }
      logger.info(`Connected to SQLite database at ${DB_PATH}`);
    });
    db.run('PRAGMA journal_mode = WAL');
    db.run('PRAGMA foreign_keys = ON');
  }
  return db;
}

function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    getDb().run(sql, params, function (err) {
      if (err) reject(err);
      else resolve({ id: this.lastID, changes: this.changes });
    });
  });
}

function get(sql, params = []) {
  return new Promise((resolve, reject) => {
    getDb().get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
}

function all(sql, params = []) {
  return new Promise((resolve, reject) => {
    getDb().all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
}

async function initializeDatabase() {
  logger.info('Initializing database schema...');

  await run(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      name TEXT NOT NULL,
      age INTEGER DEFAULT 0,
      daily_screen_time_limit INTEGER DEFAULT 7200,
      goals TEXT DEFAULT '[]',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS app_configs (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      package_name TEXT NOT NULL,
      app_name TEXT NOT NULL,
      app_icon TEXT,
      config_type TEXT NOT NULL CHECK(config_type IN ('reward', 'penalty', 'neutral')),
      minutes_per_minute REAL NOT NULL DEFAULT 0,
      is_enabled INTEGER NOT NULL DEFAULT 1,
      category TEXT DEFAULT 'Other',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      UNIQUE(user_id, package_name)
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS screen_time_entries (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      app_package_name TEXT NOT NULL,
      app_name TEXT NOT NULL,
      start_time INTEGER NOT NULL,
      end_time INTEGER,
      duration_seconds INTEGER NOT NULL DEFAULT 0,
      time_earned_or_spent INTEGER NOT NULL DEFAULT 0,
      date INTEGER NOT NULL
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS daily_summaries (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      date INTEGER NOT NULL,
      total_allocated_seconds INTEGER NOT NULL DEFAULT 7200,
      total_used_seconds INTEGER NOT NULL DEFAULT 0,
      total_earned_seconds INTEGER NOT NULL DEFAULT 0,
      total_penalty_seconds INTEGER NOT NULL DEFAULT 0,
      UNIQUE(user_id, date)
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS activities (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      type TEXT NOT NULL,
      custom_name TEXT,
      start_time INTEGER NOT NULL,
      end_time INTEGER,
      duration_seconds INTEGER NOT NULL DEFAULT 0,
      verification_method TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      reward_earned_seconds INTEGER NOT NULL DEFAULT 0,
      tap_count INTEGER NOT NULL DEFAULT 0,
      notes TEXT
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS achievements (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      icon TEXT NOT NULL,
      category TEXT NOT NULL,
      is_unlocked INTEGER NOT NULL DEFAULT 0,
      unlocked_at INTEGER,
      progress_current REAL NOT NULL DEFAULT 0,
      progress_target REAL NOT NULL DEFAULT 1,
      UNIQUE(user_id, title)
    )
  `);

  // Indexes for performance
  await run('CREATE INDEX IF NOT EXISTS idx_screen_time_user_date ON screen_time_entries(user_id, date)');
  await run('CREATE INDEX IF NOT EXISTS idx_activities_user ON activities(user_id)');
  await run('CREATE INDEX IF NOT EXISTS idx_daily_summaries_user_date ON daily_summaries(user_id, date)');
  await run('CREATE INDEX IF NOT EXISTS idx_app_configs_user ON app_configs(user_id)');

  logger.info('Database schema initialized.');
}

module.exports = { getDb, run, get, all, initializeDatabase };
