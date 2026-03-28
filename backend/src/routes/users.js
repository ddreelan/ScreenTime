'use strict';

const express = require('express');
const { body, validationResult } = require('express-validator');
const { run, get } = require('../utils/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// GET /api/v1/users/me
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const user = await get(
      'SELECT id, email, name, age, daily_screen_time_limit, default_penalty_rate, goals, created_at, updated_at FROM users WHERE id = ?',
      [req.userId]
    );
    if (!user) return res.status(404).json({ error: 'User not found' });
    user.goals = JSON.parse(user.goals || '[]');
    res.json(user);
  } catch (err) {
    next(err);
  }
});

// PUT /api/v1/users/me
router.put('/me', authenticate, [
  body('name').optional().trim().isLength({ min: 1, max: 100 }),
  body('age').optional().isInt({ min: 0, max: 120 }),
  body('dailyScreenTimeLimit').optional().isInt({ min: 0 }),
  body('defaultPenaltyRate').optional().isFloat({ min: -100, max: 0 }),
  body('goals').optional().isArray(),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    const { name, age, dailyScreenTimeLimit, defaultPenaltyRate, goals } = req.body;
    const user = await get('SELECT * FROM users WHERE id = ?', [req.userId]);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const updatedName = name !== undefined ? name : user.name;
    const updatedAge = age !== undefined ? age : user.age;
    const updatedLimit = dailyScreenTimeLimit !== undefined ? dailyScreenTimeLimit : user.daily_screen_time_limit;
    const updatedPenaltyRate = defaultPenaltyRate !== undefined ? defaultPenaltyRate : user.default_penalty_rate;
    const updatedGoals = goals !== undefined ? JSON.stringify(goals) : user.goals;

    await run(
      'UPDATE users SET name = ?, age = ?, daily_screen_time_limit = ?, default_penalty_rate = ?, goals = ?, updated_at = ? WHERE id = ?',
      [updatedName, updatedAge, updatedLimit, updatedPenaltyRate, updatedGoals, Date.now(), req.userId]
    );

    res.json({ message: 'Profile updated successfully' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
