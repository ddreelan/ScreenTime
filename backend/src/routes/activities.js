'use strict';

const express = require('express');
const { body, query, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const { run, get, all } = require('../utils/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

const VALID_ACTIVITY_TYPES = ['walking', 'running', 'cycling', 'meditation', 'reading', 'exercise', 'outdoor', 'custom'];
const VALID_STATUSES = ['pending', 'in_progress', 'verified', 'failed', 'cancelled'];
const VALID_VERIFICATION_METHODS = ['tap_count', 'scroll_detection', 'accelerometer', 'manual'];

// GET /api/v1/activities
router.get('/', authenticate, [
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 }),
  query('status').optional().isIn(VALID_STATUSES),
], async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;
    const status = req.query.status;

    const sql = status
      ? 'SELECT * FROM activities WHERE user_id = ? AND status = ? ORDER BY start_time DESC LIMIT ? OFFSET ?'
      : 'SELECT * FROM activities WHERE user_id = ? ORDER BY start_time DESC LIMIT ? OFFSET ?';
    const params = status ? [req.userId, status, limit, offset] : [req.userId, limit, offset];

    const activities = await all(sql, params);
    res.json(activities.map(toClient));
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/activities
router.post('/', authenticate, [
  body('type').isIn(VALID_ACTIVITY_TYPES),
  body('customName').optional().trim().isLength({ max: 100 }),
  body('verificationMethod').isIn(VALID_VERIFICATION_METHODS),
  body('notes').optional().trim().isLength({ max: 500 }),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    const { type, customName, verificationMethod, notes } = req.body;
    const id = uuidv4();
    const now = Date.now();

    await run(
      'INSERT INTO activities (id, user_id, type, custom_name, start_time, verification_method, status, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [id, req.userId, type, customName, now, verificationMethod, 'pending', notes]
    );

    res.status(201).json({ id, message: 'Activity created' });
  } catch (err) {
    next(err);
  }
});

// PUT /api/v1/activities/:id
router.put('/:id', authenticate, [
  body('status').optional().isIn(VALID_STATUSES),
  body('durationSeconds').optional().isInt({ min: 0 }),
  body('rewardEarnedSeconds').optional().isInt({ min: 0 }),
  body('tapCount').optional().isInt({ min: 0 }),
  body('notes').optional().trim().isLength({ max: 500 }),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    const existing = await get('SELECT * FROM activities WHERE id = ? AND user_id = ?', [req.params.id, req.userId]);
    if (!existing) return res.status(404).json({ error: 'Activity not found' });

    const { status, durationSeconds, rewardEarnedSeconds, tapCount, notes } = req.body;
    const endTime = (status === 'verified' || status === 'failed' || status === 'cancelled') ? Date.now() : existing.end_time;

    await run(
      `UPDATE activities SET
        status = COALESCE(?, status),
        end_time = COALESCE(?, end_time),
        duration_seconds = COALESCE(?, duration_seconds),
        reward_earned_seconds = COALESCE(?, reward_earned_seconds),
        tap_count = COALESCE(?, tap_count),
        notes = COALESCE(?, notes)
      WHERE id = ? AND user_id = ?`,
      [status, endTime, durationSeconds, rewardEarnedSeconds, tapCount, notes, req.params.id, req.userId]
    );

    // If verified, update today's earned seconds
    if (status === 'verified' && rewardEarnedSeconds && existing.status !== 'verified') {
      const today = new Date(); today.setHours(0,0,0,0);
      const todayMs = today.getTime();
      const summary = await get('SELECT * FROM daily_summaries WHERE user_id = ? AND date = ?', [req.userId, todayMs]);

      if (summary) {
        await run(
          'UPDATE daily_summaries SET total_earned_seconds = total_earned_seconds + ? WHERE user_id = ? AND date = ?',
          [rewardEarnedSeconds, req.userId, todayMs]
        );
      } else {
        const user = await get('SELECT daily_screen_time_limit FROM users WHERE id = ?', [req.userId]);
        await run(
          'INSERT INTO daily_summaries (id, user_id, date, total_allocated_seconds, total_used_seconds, total_earned_seconds, total_penalty_seconds) VALUES (?, ?, ?, ?, 0, ?, 0)',
          [uuidv4(), req.userId, todayMs, user?.daily_screen_time_limit || 7200, rewardEarnedSeconds]
        );
      }
    }

    res.json({ message: 'Activity updated' });
  } catch (err) {
    next(err);
  }
});

function toClient(row) {
  return {
    id: row.id,
    type: row.type,
    customName: row.custom_name,
    startTime: row.start_time,
    endTime: row.end_time,
    durationSeconds: row.duration_seconds,
    verificationMethod: row.verification_method,
    status: row.status,
    rewardEarnedSeconds: row.reward_earned_seconds,
    tapCount: row.tap_count,
    notes: row.notes,
  };
}

module.exports = router;
