'use strict';

const express = require('express');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { body, query, validationResult } = require('express-validator');
const { OAuth2Client } = require('google-auth-library');
const jwksClient = require('jwks-rsa');
const nodemailer = require('nodemailer');
const { run, get } = require('../utils/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

function getJwtSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET environment variable is not configured');
  }
  return secret;
}

// --- Email Transport ---
function getEmailTransporter() {
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: parseInt(process.env.EMAIL_PORT || '587', 10),
    secure: parseInt(process.env.EMAIL_PORT || '587', 10) === 465,
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });
}

async function sendVerificationEmail(email, token) {
  const baseUrl = process.env.APP_BASE_URL || 'http://localhost:3000';
  const verificationLink = `${baseUrl}/api/v1/auth/verify-email?token=${token}`;
  const transporter = getEmailTransporter();
  await transporter.sendMail({
    from: process.env.EMAIL_FROM || 'noreply@screentime.app',
    to: email,
    subject: 'Verify your ScreenTime email address',
    html: `<p>Welcome to ScreenTime! Please verify your email address by clicking the link below:</p><p><a href="${verificationLink}">Verify Email</a></p><p>This link expires in 24 hours.</p>`,
    text: `Welcome to ScreenTime! Verify your email address by visiting: ${verificationLink}\n\nThis link expires in 24 hours.`,
  });
}

// --- Apple JWT helpers ---
const appleJwksClient = jwksClient({
  jwksUri: 'https://appleid.apple.com/auth/keys',
  cache: true,
  rateLimit: true,
});

function getAppleSigningKey(header) {
  return new Promise((resolve, reject) => {
    appleJwksClient.getSigningKey(header.kid, (err, key) => {
      if (err) return reject(err);
      resolve(key.getPublicKey());
    });
  });
}

function verifyAppleIdToken(idToken) {
  return new Promise((resolve, reject) => {
    const decoded = jwt.decode(idToken, { complete: true });
    if (!decoded) return reject(new Error('Invalid Apple id_token'));
    getAppleSigningKey(decoded.header).then((publicKey) => {
      jwt.verify(idToken, publicKey, {
        algorithms: ['RS256'],
        issuer: 'https://appleid.apple.com',
        audience: process.env.APPLE_CLIENT_ID,
      }, (err, payload) => {
        if (err) return reject(err);
        resolve(payload);
      });
    }).catch(reject);
  });
}

function generateAppleClientSecret() {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: process.env.APPLE_TEAM_ID,
    iat: now,
    exp: now + 15777000,
    aud: 'https://appleid.apple.com',
    sub: process.env.APPLE_CLIENT_ID,
  };
  return jwt.sign(payload, process.env.APPLE_PRIVATE_KEY.replace(/\\n/g, '\n'), {
    algorithm: 'ES256',
    keyid: process.env.APPLE_KEY_ID,
  });
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

    // Email verification token
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const verificationExpires = Date.now() + 24 * 60 * 60 * 1000; // 24 hours
    await run(
      'UPDATE users SET email_verification_token = ?, email_verification_expires = ? WHERE id = ?',
      [verificationToken, verificationExpires, userId]
    );

    // Send verification email (best-effort, don't block registration)
    if (process.env.EMAIL_HOST) {
      sendVerificationEmail(email, verificationToken).catch((err) => {
        const logger = require('../utils/logger');
        logger.error('Failed to send verification email:', err);
      });
    }

    const token = jwt.sign({ userId }, getJwtSecret(), {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    });

    res.status(201).json({ token, userId, name, email, emailVerified: false });
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

    res.json({ token, userId: user.id, name: user.name, email: user.email, emailVerified: !!user.email_verified });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/auth/verify-email
router.get('/verify-email', [
  query('token').isString().notEmpty(),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { token } = req.query;
    const user = await get('SELECT * FROM users WHERE email_verification_token = ?', [token]);

    if (!user) {
      return res.status(400).json({ error: 'Invalid verification token' });
    }

    if (user.email_verification_expires < Date.now()) {
      return res.status(400).json({ error: 'Verification token has expired' });
    }

    await run(
      'UPDATE users SET email_verified = 1, email_verification_token = NULL, email_verification_expires = NULL, updated_at = ? WHERE id = ?',
      [Date.now(), user.id]
    );

    res.json({ message: 'Email verified successfully' });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/auth/resend-verification
router.post('/resend-verification', authenticate, async (req, res, next) => {
  try {
    const user = await get('SELECT * FROM users WHERE id = ?', [req.userId]);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.email_verified) {
      return res.status(400).json({ error: 'Email is already verified' });
    }

    const verificationToken = crypto.randomBytes(32).toString('hex');
    const verificationExpires = Date.now() + 24 * 60 * 60 * 1000;
    await run(
      'UPDATE users SET email_verification_token = ?, email_verification_expires = ?, updated_at = ? WHERE id = ?',
      [verificationToken, verificationExpires, Date.now(), user.id]
    );

    if (process.env.EMAIL_HOST) {
      await sendVerificationEmail(user.email, verificationToken);
    }

    res.json({ message: 'Verification email sent' });
  } catch (err) {
    next(err);
  }
});

// --- Helper: find-or-create OAuth user and seed defaults ---
async function findOrCreateOAuthUser(email, name) {
  let user = await get('SELECT * FROM users WHERE email = ?', [email]);
  if (!user) {
    const userId = uuidv4();
    const now = Date.now();
    await run(
      'INSERT INTO users (id, email, password_hash, name, age, email_verified, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 1, ?, ?)',
      [userId, email, 'oauth-no-password', name, 0, now, now]
    );

    // Seed default data for new OAuth users
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

    user = { id: userId, email, name };
  }
  return user;
}

// POST /api/v1/auth/oauth/google
router.post('/oauth/google', [
  body('idToken').optional().isString().notEmpty(),
  body('code').optional().isString().notEmpty(),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { idToken, code } = req.body;
    if (!idToken && !code) {
      return res.status(400).json({ error: 'Either idToken or code is required' });
    }

    let email, name;
    const googleClientId = process.env.GOOGLE_CLIENT_ID;
    const client = new OAuth2Client(googleClientId);

    if (idToken) {
      const ticket = await client.verifyIdToken({
        idToken,
        audience: googleClientId,
      });
      const payload = ticket.getPayload();
      email = payload.email;
      name = payload.name || 'Google User';
    } else {
      const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          code,
          client_id: googleClientId,
          client_secret: process.env.GOOGLE_CLIENT_SECRET,
          redirect_uri: process.env.GOOGLE_REDIRECT_URI || 'com.screentime.app:/oauth2callback',
          grant_type: 'authorization_code',
        }),
      });
      const tokenData = await tokenRes.json();
      if (!tokenRes.ok || !tokenData.id_token) {
        return res.status(401).json({ error: 'Failed to exchange Google authorization code' });
      }
      const ticket = await client.verifyIdToken({
        idToken: tokenData.id_token,
        audience: googleClientId,
      });
      const payload = ticket.getPayload();
      email = payload.email;
      name = payload.name || 'Google User';
    }

    if (!email) {
      return res.status(401).json({ error: 'Could not retrieve email from Google' });
    }

    const user = await findOrCreateOAuthUser(email, name);
    const token = jwt.sign({ userId: user.id }, getJwtSecret(), {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    });

    res.json({ token, userId: user.id, name: user.name || name, email: user.email || email });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/auth/oauth/apple
router.post('/oauth/apple', [
  body('idToken').optional().isString().notEmpty(),
  body('code').optional().isString().notEmpty(),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { idToken, code } = req.body;
    if (!idToken && !code) {
      return res.status(400).json({ error: 'Either idToken or code is required' });
    }

    let email, name, sub;

    if (idToken) {
      const payload = await verifyAppleIdToken(idToken);
      email = payload.email;
      sub = payload.sub;
      name = req.body.name || 'Apple User';
    } else {
      const clientSecret = generateAppleClientSecret();
      const tokenRes = await fetch('https://appleid.apple.com/auth/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          client_id: process.env.APPLE_CLIENT_ID,
          client_secret: clientSecret,
          code,
          grant_type: 'authorization_code',
          redirect_uri: process.env.GOOGLE_REDIRECT_URI || 'com.screentime.app:/oauth2callback',
        }).toString(),
      });
      const tokenData = await tokenRes.json();
      if (!tokenRes.ok || !tokenData.id_token) {
        return res.status(401).json({ error: 'Failed to exchange Apple authorization code' });
      }
      const payload = await verifyAppleIdToken(tokenData.id_token);
      email = payload.email;
      sub = payload.sub;
      name = req.body.name || 'Apple User';
    }

    // Apple may only return email on first sign-in; use sub as stable identifier
    if (!email && sub) {
      const existing = await get('SELECT * FROM users WHERE email = ?', [`apple-${sub}@privaterelay`]);
      if (existing) {
        email = existing.email;
        name = existing.name;
      } else {
        email = `apple-${sub}@privaterelay`;
      }
    }

    if (!email) {
      return res.status(401).json({ error: 'Could not retrieve email from Apple' });
    }

    const user = await findOrCreateOAuthUser(email, name || 'Apple User');
    const token = jwt.sign({ userId: user.id }, getJwtSecret(), {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    });

    res.json({ token, userId: user.id, name: user.name || name, email: user.email || email });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/auth/oauth/facebook
router.post('/oauth/facebook', [
  body('accessToken').optional().isString().notEmpty(),
  body('code').optional().isString().notEmpty(),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { accessToken, code } = req.body;
    if (!accessToken && !code) {
      return res.status(400).json({ error: 'Either accessToken or code is required' });
    }

    let fbAccessToken = accessToken;

    if (code) {
      const tokenRes = await fetch(
        `https://graph.facebook.com/v18.0/oauth/access_token?client_id=${encodeURIComponent(process.env.FACEBOOK_APP_ID)}&redirect_uri=${encodeURIComponent('com.screentime.app://oauth2callback')}&client_secret=${encodeURIComponent(process.env.FACEBOOK_APP_SECRET)}&code=${encodeURIComponent(code)}`
      );
      const tokenData = await tokenRes.json();
      if (!tokenRes.ok || !tokenData.access_token) {
        return res.status(401).json({ error: 'Failed to exchange Facebook authorization code' });
      }
      fbAccessToken = tokenData.access_token;
    }

    const profileRes = await fetch(
      `https://graph.facebook.com/me?fields=id,name,email&access_token=${encodeURIComponent(fbAccessToken)}`
    );
    const profile = await profileRes.json();
    if (!profileRes.ok || !profile.email) {
      return res.status(401).json({ error: 'Could not retrieve email from Facebook' });
    }

    const email = profile.email;
    const name = profile.name || 'Facebook User';

    const user = await findOrCreateOAuthUser(email, name);
    const token = jwt.sign({ userId: user.id }, getJwtSecret(), {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    });

    res.json({ token, userId: user.id, name: user.name || name, email: user.email || email });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
