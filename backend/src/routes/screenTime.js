'use strict';

const express = require('express');
const { body, query, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const { run, get, all } = require('../utils/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

function todayStart() {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d.getTime();
}

// GET /api/v1/screen-time/summary/today
router.get('/summary/today', authenticate, async (req, res, next) => {
  try {
    const today = todayStart();
    let summary = await get(
      'SELECT * FROM daily_summaries WHERE user_id = ? AND date = ?',
      [req.userId, today]
    );

    if (!summary) {
      const user = await get('SELECT daily_screen_time_limit FROM users WHERE id = ?', [req.userId]);
      summary = {
        id: uuidv4(),
        user_id: req.userId,
        date: today,
        total_allocated_seconds: user?.daily_screen_time_limit || 7200,
        total_used_seconds: 0,
        total_earned_seconds: 0,
        total_penalty_seconds: 0,
      };
    }

    res.json(toClientSummary(summary));
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/screen-time/summaries
router.get('/summaries', authenticate, [
  query('days').optional().isInt({ min: 1, max: 90 }),
], async (req, res, next) => {
  try {
    const days = parseInt(req.query.days) || 7;
    const cutoff = Date.now() - days * 24 * 60 * 60 * 1000;
    const summaries = await all(
      'SELECT * FROM daily_summaries WHERE user_id = ? AND date >= ? ORDER BY date DESC',
      [req.userId, cutoff]
    );
    res.json(summaries.map(toClientSummary));
  } catch (err) {
    next(err);
  }
});

// PUT /api/v1/screen-time/summary/today
router.put('/summary/today', authenticate, [
  body('totalUsedSeconds').optional().isInt({ min: 0 }),
  body('totalEarnedSeconds').optional().isInt({ min: 0 }),
  body('totalPenaltySeconds').optional().isInt({ min: 0 }),
  body('totalAllocatedSeconds').optional().isInt({ min: 0 }),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    const today = todayStart();
    const existing = await get('SELECT * FROM daily_summaries WHERE user_id = ? AND date = ?', [req.userId, today]);
    const user = await get('SELECT daily_screen_time_limit FROM users WHERE id = ?', [req.userId]);

    const { totalUsedSeconds, totalEarnedSeconds, totalPenaltySeconds, totalAllocatedSeconds } = req.body;

    if (existing) {
      await run(
        `UPDATE daily_summaries SET
          total_used_seconds = COALESCE(?, total_used_seconds),
          total_earned_seconds = COALESCE(?, total_earned_seconds),
          total_penalty_seconds = COALESCE(?, total_penalty_seconds),
          total_allocated_seconds = COALESCE(?, total_allocated_seconds)
        WHERE user_id = ? AND date = ?`,
        [totalUsedSeconds, totalEarnedSeconds, totalPenaltySeconds, totalAllocatedSeconds, req.userId, today]
      );
    } else {
      await run(
        'INSERT INTO daily_summaries (id, user_id, date, total_allocated_seconds, total_used_seconds, total_earned_seconds, total_penalty_seconds) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [uuidv4(), req.userId, today, totalAllocatedSeconds || user?.daily_screen_time_limit || 7200, totalUsedSeconds || 0, totalEarnedSeconds || 0, totalPenaltySeconds || 0]
      );
    }

    res.json({ message: 'Summary updated' });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/screen-time/entries
router.post('/entries', authenticate, [
  body('appPackageName').trim().notEmpty(),
  body('appName').trim().notEmpty(),
  body('durationSeconds').isInt({ min: 0 }),
  body('startTime').optional().isInt(),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    const { appPackageName, appName, durationSeconds, startTime = Date.now() } = req.body;
    const today = todayStart();
    const id = uuidv4();

    await run(
      'INSERT INTO screen_time_entries (id, user_id, app_package_name, app_name, start_time, duration_seconds, date) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, req.userId, appPackageName, appName, startTime, durationSeconds, today]
    );

    res.status(201).json({ id, message: 'Screen time entry recorded' });
  } catch (err) {
    next(err);
  }
});

function toClientSummary(row) {
  const remaining = Math.max(0, (row.total_allocated_seconds + row.total_earned_seconds) - row.total_used_seconds - row.total_penalty_seconds);
  return {
    id: row.id,
    date: row.date,
    totalAllocatedSeconds: row.total_allocated_seconds,
    totalUsedSeconds: row.total_used_seconds,
    totalEarnedSeconds: row.total_earned_seconds,
    totalPenaltySeconds: row.total_penalty_seconds,
    remainingSeconds: remaining,
    usagePercentage: Math.min(1, row.total_used_seconds / Math.max(1, row.total_allocated_seconds + row.total_earned_seconds)),
  };
}

// POST /api/v1/screen-time/timeline
router.post('/timeline', authenticate, [
  body('timestamp').isInt(),
  body('remainingSeconds').isFloat(),
  body('activeAppName').optional({ nullable: true }).isString(),
  body('activeAppPackageName').optional({ nullable: true }).isString(),
  body('delta').isFloat(),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    const { timestamp, remainingSeconds, activeAppName, activeAppPackageName, delta } = req.body;
    const id = uuidv4();
    await run(
      'INSERT INTO timeline_data_points (id, user_id, timestamp, remaining_seconds, active_app_name, active_app_package_name, delta) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, req.userId, timestamp, remainingSeconds, activeAppName || null, activeAppPackageName || null, delta]
    );
    res.status(201).json({ id, message: 'Timeline point recorded' });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/screen-time/timeline?date=YYYY-MM-DD
router.get('/timeline', authenticate, [
  query('date').optional().isISO8601(),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    let startOfDay, endOfDay;
    if (req.query.date) {
      const d = new Date(req.query.date);
      d.setHours(0, 0, 0, 0);
      startOfDay = d.getTime();
      d.setHours(23, 59, 59, 999);
      endOfDay = d.getTime();
    } else {
      const d = new Date();
      d.setHours(0, 0, 0, 0);
      startOfDay = d.getTime();
      endOfDay = Date.now();
    }

    const points = await all(
      'SELECT * FROM timeline_data_points WHERE user_id = ? AND timestamp >= ? AND timestamp <= ? ORDER BY timestamp ASC',
      [req.userId, startOfDay, endOfDay]
    );

    res.json(points.map(p => ({
      id: p.id,
      timestamp: p.timestamp,
      remainingSeconds: p.remaining_seconds,
      activeAppName: p.active_app_name,
      activeAppPackageName: p.active_app_package_name,
      delta: p.delta,
    })));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
