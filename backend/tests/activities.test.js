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
    email: 'activity-test@example.com', password: 'password123', name: 'Activity User',
  });
  authToken = res.body.token;
});

describe('Activities API', () => {
  let activityId;

  it('should create an activity', async () => {
    const res = await request(app)
      .post('/api/v1/activities')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ type: 'walking', verificationMethod: 'accelerometer' });
    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
    activityId = res.body.id;
  });

  it('should list activities', async () => {
    const res = await request(app).get('/api/v1/activities').set('Authorization', `Bearer ${authToken}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('should verify an activity and update earned time', async () => {
    const res = await request(app)
      .put(`/api/v1/activities/${activityId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ status: 'verified', durationSeconds: 900, rewardEarnedSeconds: 600 });
    expect(res.status).toBe(200);
  });

  it('should reject invalid activity type', async () => {
    const res = await request(app)
      .post('/api/v1/activities')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ type: 'invalid_type', verificationMethod: 'manual' });
    expect(res.status).toBe(400);
  });
});
