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
});
