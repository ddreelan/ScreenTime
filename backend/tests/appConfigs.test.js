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
    email: 'config-test@example.com', password: 'password123', name: 'Config User',
  });
  authToken = res.body.token;
});

describe('App Configs API', () => {
  let configId;

  it('should create a reward app config', async () => {
    const res = await request(app)
      .post('/api/v1/app-configs')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        packageName: 'com.test.fitness',
        appName: 'Test Fitness',
        configType: 'reward',
        minutesPerMinute: 1.5,
        category: 'Health',
      });
    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
    configId = res.body.id;
  });

  it('should list app configs', async () => {
    const res = await request(app).get('/api/v1/app-configs').set('Authorization', `Bearer ${authToken}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
  });

  it('should update an app config', async () => {
    const res = await request(app)
      .put(`/api/v1/app-configs/${configId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ minutesPerMinute: 2.0 });
    expect(res.status).toBe(200);
  });

  it('should delete an app config', async () => {
    const res = await request(app)
      .delete(`/api/v1/app-configs/${configId}`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.status).toBe(200);
  });

  it('should reject unauthenticated requests', async () => {
    const res = await request(app).get('/api/v1/app-configs');
    expect(res.status).toBe(401);
  });
});
