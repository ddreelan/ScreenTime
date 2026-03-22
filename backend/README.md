# ScreenTime Backend API

A Node.js/Express REST API providing backend services for the ScreenTime mobile app.

## Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js 4
- **Database**: SQLite 3 (via `sqlite3`)
- **Auth**: JWT (jsonwebtoken) + bcrypt
- **Validation**: express-validator
- **Security**: helmet, cors, express-rate-limit

## Quick Start

```bash
cd backend
cp .env.example .env
# Edit .env with your JWT_SECRET
npm install
npm run dev
```

## API Endpoints

### Authentication
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | Login and get JWT |

### User Profile
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/users/me` | Get own profile |
| PUT | `/api/v1/users/me` | Update profile + daily limit |

### App Configurations
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/app-configs` | List all configs |
| POST | `/api/v1/app-configs` | Create reward/penalty config |
| PUT | `/api/v1/app-configs/:id` | Update config |
| DELETE | `/api/v1/app-configs/:id` | Delete config |

### Screen Time
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/screen-time/summary/today` | Get today's summary |
| GET | `/api/v1/screen-time/summaries?days=7` | Get recent summaries |
| PUT | `/api/v1/screen-time/summary/today` | Update today's usage |
| POST | `/api/v1/screen-time/entries` | Log a screen time entry |

### Activities
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/activities` | List activities |
| POST | `/api/v1/activities` | Start new activity |
| PUT | `/api/v1/activities/:id` | Update activity status |

### Analytics
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/analytics/overview?days=7` | Usage analytics |

### Achievements
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/achievements` | List all achievements |
| PUT | `/api/v1/achievements/:id` | Update progress/unlock |

## Security Features

- JWT authentication on all protected routes
- Rate limiting (100 req/15 min)
- Helmet security headers
- Input validation on all endpoints
- Password hashing with bcrypt (12 rounds)
- Foreign key cascading for user data isolation
- SQL injection protection via parameterized queries

## Running Tests

```bash
npm test
```
