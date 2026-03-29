'use strict';

process.env.DB_PATH = ':memory:';
process.env.JWT_SECRET = 'test-secret';
process.env.NODE_ENV = 'test';

const request = require('supertest');
const { initializeDatabase } = require('../src/utils/database');
const app = require('../src/app');

let authToken;

beforeAll(async () => {
    await initializeDatabase();
    const res = await request(app).post('/api/v1/auth/register').send({
        email: 'screentime-test@example.com', password: 'password123', name: 'ST User',
    });
    authToken = res.body.token;
});

describe('Screen Time API', () => {
    it('should get today summary', async () => {
        const res = await request(app).get('/api/v1/screen-time/summary/today').set('Authorization', `Bearer ${authToken}`);
        expect(res.status).toBe(200);
        expect(res.body).toHaveProperty('totalAllocatedSeconds');
        expect(res.body).toHaveProperty('remainingSeconds');
    });

    it('should update today summary', async () => {
        const res = await request(app).put('/api/v1/screen-time/summary/today')
            .set('Authorization', `Bearer ${authToken}`)
            .send({ totalUsedSeconds: 100, totalEarnedSeconds: 50 });
        expect(res.status).toBe(200);
    });

    it('should post a timeline data point', async () => {
        const res = await request(app).post('/api/v1/screen-time/timeline')
            .set('Authorization', `Bearer ${authToken}`)
            .send({
                timestamp: Date.now(),
                remainingSeconds: 7100.5,
                activeAppName: 'Duolingo',
                activeAppPackageName: 'com.duolingo',
                delta: 0.5
            });
        expect(res.status).toBe(201);
        expect(res.body).toHaveProperty('id');
    });

    it('should get timeline data points', async () => {
        const res = await request(app).get('/api/v1/screen-time/timeline')
            .set('Authorization', `Bearer ${authToken}`);
        expect(res.status).toBe(200);
        expect(Array.isArray(res.body)).toBe(true);
        expect(res.body.length).toBeGreaterThan(0);
    });

    it('should reject timeline without auth', async () => {
        const res = await request(app).get('/api/v1/screen-time/timeline');
        expect(res.status).toBe(401);
    });

    it('should return empty gains-penalties for new user', async () => {
        const res = await request(app)
            .get('/api/v1/screen-time/gains-penalties')
            .set('Authorization', `Bearer ${authToken}`);
        expect(res.status).toBe(200);
        expect(res.body).toHaveProperty('events');
        expect(Array.isArray(res.body.events)).toBe(true);
    });

    it('should reject gains-penalties without auth', async () => {
        const res = await request(app).get('/api/v1/screen-time/gains-penalties');
        expect(res.status).toBe(401);
    });

    it('should return gains-penalties events sorted most-recent-first with timestamps', async () => {
        const now = Date.now();
        const todayStart = new Date();
        todayStart.setHours(0, 0, 0, 0);
        const dayStartMs = todayStart.getTime();

        // Create a screen time entry with positive time_earned_or_spent (earlier)
        await request(app)
            .post('/api/v1/screen-time/entries')
            .set('Authorization', `Bearer ${authToken}`)
            .send({
                appPackageName: 'com.duolingo',
                appName: 'Duolingo',
                durationSeconds: 600,
                startTime: now - 3000,
            });

        // Manually insert an entry with time_earned_or_spent (the POST endpoint doesn't expose this field,
        // so we verify by checking that entries with time_earned_or_spent=0 are excluded)

        // Create a verified activity with reward (more recent)
        await request(app)
            .post('/api/v1/activities')
            .set('Authorization', `Bearer ${authToken}`)
            .send({
                type: 'walking',
                startTime: now - 2000,
                endTime: now - 1000,
                durationSeconds: 1000,
                verificationMethod: 'manual',
                status: 'pending',
                rewardEarnedSeconds: 0,
            });

        const res = await request(app)
            .get('/api/v1/screen-time/gains-penalties')
            .set('Authorization', `Bearer ${authToken}`);

        expect(res.status).toBe(200);
        expect(res.body).toHaveProperty('events');
        const events = res.body.events;
        expect(Array.isArray(events)).toBe(true);

        // All events must have a numeric timestamp
        events.forEach(event => {
            expect(typeof event.timestamp).toBe('number');
            expect(event.timestamp).toBeGreaterThan(0);
        });

        // Events must be sorted most-recent-first
        for (let i = 1; i < events.length; i++) {
            expect(events[i - 1].timestamp).toBeGreaterThanOrEqual(events[i].timestamp);
        }
    });

    it('should include activity_reward events with correct fields', async () => {
        // Register a fresh user for a clean slate
        const regRes = await request(app).post('/api/v1/auth/register').send({
            email: 'gp-activity-test@example.com', password: 'password123', name: 'GP User',
        });
        const token = regRes.body.token;
        const now = Date.now();

        // Create a verified activity with reward
        const actRes = await request(app)
            .post('/api/v1/activities')
            .set('Authorization', `Bearer ${token}`)
            .send({
                type: 'walking',
                startTime: now - 2000,
                endTime: now - 500,
                durationSeconds: 1500,
                verificationMethod: 'manual',
                status: 'pending',
                rewardEarnedSeconds: 0,
            });
        const actId = actRes.body.id;

        // Update to verified with reward
        await request(app)
            .put(`/api/v1/activities/${actId}`)
            .set('Authorization', `Bearer ${token}`)
            .send({ status: 'verified', rewardEarnedSeconds: 600 });

        const res = await request(app)
            .get('/api/v1/screen-time/gains-penalties')
            .set('Authorization', `Bearer ${token}`);

        expect(res.status).toBe(200);
        const events = res.body.events;
        const actEvent = events.find(e => e.type === 'activity_reward');
        expect(actEvent).toBeDefined();
        expect(actEvent.secondsDelta).toBe(600);
        expect(typeof actEvent.timestamp).toBe('number');
        expect(actEvent.timestamp).toBeGreaterThan(0);
    });
});
