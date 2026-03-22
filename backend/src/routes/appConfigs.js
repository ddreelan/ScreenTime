'use strict';

const express = require('express');
const { body, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const { run, get, all } = require('../utils/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// GET /api/v1/app-configs
router.get('/', authenticate, async (req, res, next) => {
  try {
    const configs = await all(
      'SELECT * FROM app_configs WHERE user_id = ? ORDER BY app_name ASC',
      [req.userId]
    );
    res.json(configs.map(toClient));
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/app-configs/:id
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const config = await get(
      'SELECT * FROM app_configs WHERE id = ? AND user_id = ?',
      [req.params.id, req.userId]
    );
    if (!config) return res.status(404).json({ error: 'App config not found' });
    res.json(toClient(config));
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/app-configs
router.post('/', authenticate, [
  body('packageName').trim().notEmpty(),
  body('appName').trim().isLength({ min: 1, max: 100 }),
  body('configType').isIn(['reward', 'penalty', 'neutral']),
  body('minutesPerMinute').isFloat({ min: -10, max: 10 }),
  body('isEnabled').optional().isBoolean(),
  body('category').optional().trim().isLength({ max: 50 }),
  body('appIcon').optional().trim(),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    const { packageName, appName, configType, minutesPerMinute, isEnabled = true, category = 'Other', appIcon } = req.body;
    const now = Date.now();
    const id = uuidv4();

    await run(
      'INSERT OR REPLACE INTO app_configs (id, user_id, package_name, app_name, app_icon, config_type, minutes_per_minute, is_enabled, category, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [id, req.userId, packageName, appName, appIcon, configType, minutesPerMinute, isEnabled ? 1 : 0, category, now, now]
    );

    res.status(201).json({ id, message: 'App config created' });
  } catch (err) {
    next(err);
  }
});

// PUT /api/v1/app-configs/:id
router.put('/:id', authenticate, [
  body('appName').optional().trim().isLength({ min: 1, max: 100 }),
  body('configType').optional().isIn(['reward', 'penalty', 'neutral']),
  body('minutesPerMinute').optional().isFloat({ min: -10, max: 10 }),
  body('isEnabled').optional().isBoolean(),
  body('category').optional().trim().isLength({ max: 50 }),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    const existing = await get('SELECT * FROM app_configs WHERE id = ? AND user_id = ?', [req.params.id, req.userId]);
    if (!existing) return res.status(404).json({ error: 'App config not found' });

    const { appName, configType, minutesPerMinute, isEnabled, category, appIcon } = req.body;
    await run(
      `UPDATE app_configs SET
        app_name = COALESCE(?, app_name),
        app_icon = COALESCE(?, app_icon),
        config_type = COALESCE(?, config_type),
        minutes_per_minute = COALESCE(?, minutes_per_minute),
        is_enabled = COALESCE(?, is_enabled),
        category = COALESCE(?, category),
        updated_at = ?
      WHERE id = ? AND user_id = ?`,
      [appName, appIcon, configType, minutesPerMinute, isEnabled !== undefined ? (isEnabled ? 1 : 0) : null, category, Date.now(), req.params.id, req.userId]
    );

    res.json({ message: 'App config updated' });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/v1/app-configs/:id
router.delete('/:id', authenticate, async (req, res, next) => {
  try {
    const result = await run(
      'DELETE FROM app_configs WHERE id = ? AND user_id = ?',
      [req.params.id, req.userId]
    );
    if (result.changes === 0) return res.status(404).json({ error: 'App config not found' });
    res.json({ message: 'App config deleted' });
  } catch (err) {
    next(err);
  }
});

function toClient(row) {
  return {
    id: row.id,
    packageName: row.package_name,
    appName: row.app_name,
    appIcon: row.app_icon,
    configType: row.config_type,
    minutesPerMinute: row.minutes_per_minute,
    isEnabled: Boolean(row.is_enabled),
    category: row.category,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

module.exports = router;
