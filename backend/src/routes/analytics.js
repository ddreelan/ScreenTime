'use strict';

const express = require('express');
const { query, validationResult } = require('express-validator');
const { all, get } = require('../utils/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// GET /api/v1/analytics/overview
router.get('/overview', authenticate, [
  query('days').optional().isInt({ min: 1, max: 90 }),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    const days = parseInt(req.query.days) || 7;
    const cutoff = Date.now() - days * 24 * 60 * 60 * 1000;

    const summaries = await all(
      'SELECT * FROM daily_summaries WHERE user_id = ? AND date >= ? ORDER BY date ASC',
      [req.userId, cutoff]
    );

    const activities = await all(
      'SELECT * FROM activities WHERE user_id = ? AND start_time >= ? AND status = ? ORDER BY start_time DESC',
      [req.userId, cutoff, 'verified']
    );

    const appConfigs = await all(
      'SELECT * FROM app_configs WHERE user_id = ?',
      [req.userId]
    );

    const avgDailyUse = summaries.length > 0
      ? summaries.reduce((sum, s) => sum + s.total_used_seconds, 0) / summaries.length
      : 0;

    const avgDailyEarned = summaries.length > 0
      ? summaries.reduce((sum, s) => sum + s.total_earned_seconds, 0) / summaries.length
      : 0;

    const activityBreakdown = activities.reduce((acc, a) => {
      acc[a.type] = (acc[a.type] || 0) + 1;
      return acc;
    }, {});

    res.json({
      period: { days, startDate: cutoff, endDate: Date.now() },
      averages: {
        dailyUseSeconds: Math.round(avgDailyUse),
        dailyEarnedSeconds: Math.round(avgDailyEarned),
      },
      totals: {
        activitiesCompleted: activities.length,
        totalEarnedSeconds: activities.reduce((sum, a) => sum + a.reward_earned_seconds, 0),
        daysTracked: summaries.length,
      },
      activityBreakdown,
      rewardAppsCount: appConfigs.filter(c => c.config_type === 'reward').length,
      penaltyAppsCount: appConfigs.filter(c => c.config_type === 'penalty').length,
      dailySummaries: summaries.map(s => ({
        date: s.date,
        usedSeconds: s.total_used_seconds,
        earnedSeconds: s.total_earned_seconds,
        allocatedSeconds: s.total_allocated_seconds,
        remainingSeconds: Math.max(0, (s.total_allocated_seconds + s.total_earned_seconds) - s.total_used_seconds - s.total_penalty_seconds),
      })),
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
