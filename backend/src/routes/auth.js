'use strict';

const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { body, validationResult } = require('express-validator');
const { run, get } = require('../utils/database');

const router = express.Router();

function getJwtSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET environment variable is not configured');
  }
  return secret;
}

const DEFAULT_ACHIEVEMENTS = [
  { title: 'First Steps', description: 'Complete your first activity', icon: 'star', category: 'activity', progressTarget: 1 },
  { title: 'Week Warrior', description: 'Stay within screen time limit for 7 days', icon: 'calendar', category: 'streak', progressTarget: 7 },
  { title: 'Activity Champion', description: 'Complete 10 activities', icon: 'trophy', category: 'activity', progressTarget: 10 },
  { title: 'Digital Detox', description: 'Use less than 1 hour of screen time in a day', icon: 'leaf', category: 'screenTime', progressTarget: 1 },
];

const DEFAULT_REWARD_APPS = [
  { packageName: 'com.google.android.apps.fitness', appName: 'Google Fit', appIcon: 'favorite', configType: 'reward', minutesPerMinute: 2.0, category: 'Health' },
  { packageName: 'com.duolingo', appName: 'Duolingo', appIcon: 'translate', configType: 'reward', minutesPerMinute: 1.0, category: 'Education' },
  { packageName: 'com.headspace.android', appName: 'Headspace', appIcon: 'self_improvement', configType: 'reward', minutesPerMinute: 1.2, category: 'Wellness' },
];

const DEFAULT_PENALTY_APPS = [
  { packageName: 'com.zhiliaoapp.musically', appName: 'TikTok', appIcon: 'play_circle', configType: 'penalty', minutesPerMinute: -2.0, category: 'Entertainment' },
  { packageName: 'com.instagram.android', appName: 'Instagram', appIcon: 'camera_alt', configType: 'penalty', minutesPerMinute: -1.5, category: 'Social' },
];

// POST /api/v1/auth/register
router.post('/register', [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('name').trim().isLength({ min: 1, max: 100 }),
  body('age').optional().isInt({ min: 0, max: 120 }),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password, name, age = 0 } = req.body;

    const existing = await get('SELECT id FROM users WHERE email = ?', [email]);
    if (existing) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const userId = uuidv4();
    const now = Date.now();

    await run(
      'INSERT INTO users (id, email, password_hash, name, age, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [userId, email, passwordHash, name, age, now, now]
    );

    // Seed default data
    const appSeedData = [...DEFAULT_REWARD_APPS, ...DEFAULT_PENALTY_APPS];
    for (const app of appSeedData) {
      await run(
        'INSERT OR IGNORE INTO app_configs (id, user_id, package_name, app_name, app_icon, config_type, minutes_per_minute, is_enabled, category, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?)',
        [uuidv4(), userId, app.packageName, app.appName, app.appIcon, app.configType, app.minutesPerMinute, app.category, now, now]
      );
    }
    for (const ach of DEFAULT_ACHIEVEMENTS) {
      await run(
        'INSERT OR IGNORE INTO achievements (id, user_id, title, description, icon, category, progress_target) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [uuidv4(), userId, ach.title, ach.description, ach.icon, ach.category, ach.progressTarget]
      );
    }

    const token = jwt.sign({ userId }, getJwtSecret(), {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    });

    res.status(201).json({ token, userId, name, email });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/auth/login
router.post('/login', [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty(),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password } = req.body;
    const user = await get('SELECT * FROM users WHERE email = ?', [email]);

    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign({ userId: user.id }, getJwtSecret(), {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    });

    res.json({ token, userId: user.id, name: user.name, email: user.email });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
