'use strict';

const request = require('supertest');

// Use in-memory DB for tests
process.env.DB_PATH = ':memory:';
process.env.JWT_SECRET = 'test-secret';
process.env.NODE_ENV = 'test';

const { initializeDatabase } = require('../src/utils/database');
const app = require('../src/app');

beforeAll(async () => {
  await initializeDatabase();
});

describe('Auth API', () => {
  const testUser = { email: 'test@example.com', password: 'password123', name: 'Test User', age: 25 };

  describe('POST /api/v1/auth/register', () => {
    it('should register a new user', async () => {
      const res = await request(app).post('/api/v1/auth/register').send(testUser);
      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('token');
      expect(res.body).toHaveProperty('userId');
      expect(res.body.name).toBe(testUser.name);
    });

    it('should reject duplicate email', async () => {
      const res = await request(app).post('/api/v1/auth/register').send(testUser);
      expect(res.status).toBe(409);
    });

    it('should reject invalid email', async () => {
      const res = await request(app).post('/api/v1/auth/register').send({ ...testUser, email: 'not-an-email' });
      expect(res.status).toBe(400);
    });

    it('should reject short password', async () => {
      const res = await request(app).post('/api/v1/auth/register').send({ ...testUser, email: 'new@test.com', password: 'short' });
      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/v1/auth/login', () => {
    it('should login with valid credentials', async () => {
      const res = await request(app).post('/api/v1/auth/login').send({ email: testUser.email, password: testUser.password });
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('token');
    });

    it('should reject wrong password', async () => {
      const res = await request(app).post('/api/v1/auth/login').send({ email: testUser.email, password: 'wrongpassword' });
      expect(res.status).toBe(401);
    });

    it('should reject non-existent user', async () => {
      const res = await request(app).post('/api/v1/auth/login').send({ email: 'nobody@test.com', password: 'password123' });
      expect(res.status).toBe(401);
    });
  });
});

describe('Health check', () => {
  it('GET /health should return ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
