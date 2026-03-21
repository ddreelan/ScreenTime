'use strict';

const express = require('express');
const { body, validationResult } = require('express-validator');
const { run, get, all } = require('../utils/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// GET /api/v1/achievements
router.get('/', authenticate, async (req, res, next) => {
  try {
    const achievements = await all(
      'SELECT * FROM achievements WHERE user_id = ? ORDER BY is_unlocked DESC, title ASC',
      [req.userId]
    );
    res.json(achievements.map(toClient));
  } catch (err) {
    next(err);
  }
});

// PUT /api/v1/achievements/:id
router.put('/:id', authenticate, [
  body('isUnlocked').optional().isBoolean(),
  body('progressCurrent').optional().isFloat({ min: 0 }),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    const existing = await get('SELECT * FROM achievements WHERE id = ? AND user_id = ?', [req.params.id, req.userId]);
    if (!existing) return res.status(404).json({ error: 'Achievement not found' });

    const { isUnlocked, progressCurrent } = req.body;
    const unlockedAt = isUnlocked && !existing.is_unlocked ? Date.now() : existing.unlocked_at;

    await run(
      `UPDATE achievements SET
        is_unlocked = COALESCE(?, is_unlocked),
        unlocked_at = COALESCE(?, unlocked_at),
        progress_current = COALESCE(?, progress_current)
      WHERE id = ? AND user_id = ?`,
      [isUnlocked !== undefined ? (isUnlocked ? 1 : 0) : null, unlockedAt, progressCurrent, req.params.id, req.userId]
    );

    res.json({ message: 'Achievement updated' });
  } catch (err) {
    next(err);
  }
});

function toClient(row) {
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    icon: row.icon,
    category: row.category,
    isUnlocked: Boolean(row.is_unlocked),
    unlockedAt: row.unlocked_at,
    progressCurrent: row.progress_current,
    progressTarget: row.progress_target,
  };
}

module.exports = router;
