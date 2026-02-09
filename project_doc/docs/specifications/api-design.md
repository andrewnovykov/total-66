# API Design Specification

## API Style

- [x] REST
- [ ] GraphQL
- [ ] tRPC
- [ ] gRPC
- [ ] Hybrid

HeadsUp uses a RESTful JSON API for backend data operations combined with Phoenix LiveView for real-time UI interactions.

---

## Base URL & Versioning

| Environment | Base URL                              |
| ----------- | ------------------------------------- |
| Development | `http://localhost:4000/api`           |
| Preview     | `https://{pr-name}.onrender.com/api`  |
| Production  | `https://heads-up.onrender.com/api`   |

**Versioning strategy:**

- [x] No versioning (single active version)
- [ ] URL path (`/api/v1/...`)
- [ ] Header (`Accept: application/vnd.api+json; version=1`)

Currently using unversioned API. Future versions will use URL path versioning (`/api/v2/...`).

---

## Standard Response Envelope

### Success Response (Single Resource)

```json
{
  "goal": {
    "id": 1,
    "title": "Learn Elixir",
    "status": "active",
    "progress": 45,
    "user_id": 1,
    "inserted_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-20T14:22:00Z"
  }
}
```

### Success Response (Collection)

```json
{
  "goals": [
    { "id": 1, "title": "Learn Elixir", ... },
    { "id": 2, "title": "Build App", ... }
  ],
  "page": 1,
  "per_page": 20,
  "total": 45
}
```

### Success Response (Action)

```json
{
  "status": "ok",
  "message": "Goal liked successfully"
}
```

### Error Response

```json
{
  "error": "Unauthorized",
  "message": "You must be logged in to perform this action"
}
```

### Validation Error Response

```json
{
  "errors": {
    "title": ["can't be blank"],
    "category_id": ["is invalid"]
  }
}
```

---

## Standard Error Codes

| Code               | HTTP Status | Description                           |
| ------------------ | ----------- | ------------------------------------- |
| `Unauthorized`     | 401         | Missing or invalid session            |
| `Forbidden`        | 403         | Insufficient permissions / not owner  |
| `Not Found`        | 404         | Resource does not exist               |
| `Unprocessable`    | 422         | Validation errors in request body     |
| `Internal Error`   | 500         | Unexpected server error               |

---

## Pagination Strategy

- [x] Offset-based (simpler, good for static lists)
- [ ] Cursor-based (recommended for real-time data)

**Offset-based parameters:**

| Parameter  | Type   | Default | Max | Description         |
| ---------- | ------ | ------- | --- | ------------------- |
| `page`     | number | 1       | —   | Page number         |
| `per_page` | number | 20      | 100 | Items per page      |
| `limit`    | number | 20      | 100 | Alias for per_page  |

**Response includes:**

```json
{
  "goals": [...],
  "page": 1,
  "per_page": 20,
  "total": 150
}
```

---

## Rate Limiting

Currently not implemented. Future implementation:

| Scope           | Limit    | Window  |
| --------------- | -------- | ------- |
| Authenticated   | 100 req  | 1 min   |
| Unauthenticated | 20 req   | 1 min   |
| Auth endpoints  | 5 req    | 1 min   |

---

## Authentication

HeadsUp uses **session-based authentication** (not JWT tokens).

### Session Cookie

All authenticated requests include a session cookie set during login:

```
Cookie: _heads_up_key=<session_id>
```

### Authentication Flow

1. User logs in via `POST /users/log_in` (form data)
2. Server sets session cookie
3. Subsequent requests include cookie automatically
4. API extracts user from `conn.assigns[:current_user]`

### Unauthenticated Response

```json
{
  "error": "Unauthorized",
  "message": "You must be logged in to perform this action"
}
```

---

## API Pipelines

### `:api` Pipeline (Public)

- Accepts JSON
- Fetches session (optional auth)
- Fetches current user if session exists

### `:api_auth` Pipeline (Authenticated)

- Accepts JSON
- Requires valid session
- Returns 401 if no user

### `:api_admin` Pipeline (Admin Only)

- Extends `:api_auth`
- Requires `role: :admin`
- Returns 403 if not admin

---

## Resource: Goals

Base path: `/api/goals`

### Public Endpoints

| Method | Path                        | Auth   | Description                    |
| ------ | --------------------------- | ------ | ------------------------------ |
| GET    | `/`                         | None   | List all public goals          |
| GET    | `/:id`                      | None   | Get goal (respects privacy)    |
| GET    | `/category/:category_id`    | None   | Get public goals in category   |

### Authenticated Endpoints

| Method | Path             | Auth | Description                    |
| ------ | ---------------- | ---- | ------------------------------ |
| GET    | `/my`            | User | Get current user's goals       |
| GET    | `/deleted`       | User | Get user's deleted goals       |
| POST   | `/`              | User | Create new goal                |
| PUT    | `/:id`           | User | Update goal (owner only)       |
| DELETE | `/:id`           | User | Soft delete goal (owner only)  |

### Goal Interactions

| Method | Path              | Auth | Description                    |
| ------ | ----------------- | ---- | ------------------------------ |
| POST   | `/:id/like`       | User | Like a goal (not own)          |
| DELETE | `/:id/like`       | User | Unlike a goal                  |
| POST   | `/:id/subscribe`  | User | Subscribe to goal              |
| DELETE | `/:id/subscribe`  | User | Unsubscribe from goal          |

### Goal Management

| Method | Path              | Auth | Description                    |
| ------ | ----------------- | ---- | ------------------------------ |
| POST   | `/:id/restore`    | User | Restore soft-deleted goal      |
| POST   | `/:id/fail`       | User | Mark goal as failed            |
| POST   | `/:id/freeze`     | User | Freeze/pause goal              |
| POST   | `/:id/unfreeze`   | User | Unfreeze goal                  |

**Query Parameters (GET /goals):**

| Parameter  | Type   | Description                              |
| ---------- | ------ | ---------------------------------------- |
| `status`   | string | Filter by status (active, completed, paused, cancelled) |
| `search`   | string | Full-text search in title/description    |
| `sort`     | string | Sort order (see below)                   |
| `page`     | number | Page number                              |
| `per_page` | number | Items per page                           |

**Sort Options:**

- `created_desc` (default), `created_asc`
- `updated_desc`, `updated_asc`
- `progress_desc`, `progress_asc`
- `title_asc`, `title_desc`

---

## Resource: Categories

Base path: `/api/categories`

### Public Endpoints

| Method | Path                    | Auth  | Description                   |
| ------ | ----------------------- | ----- | ----------------------------- |
| GET    | `/`                     | None  | List all categories           |
| GET    | `/:id`                  | None  | Get category details          |
| GET    | `/:id/subcategories`    | None  | List subcategories            |

### Admin Endpoints

| Method | Path                    | Auth  | Description                   |
| ------ | ----------------------- | ----- | ----------------------------- |
| POST   | `/admin/categories`     | Admin | Create category               |
| PUT    | `/admin/categories/:id` | Admin | Update category               |
| DELETE | `/admin/categories/:id` | Admin | Delete category               |

---

## Resource: Users / Relationships

Base path: `/api/users`, `/api/friends`, `/api/friend-requests`

### Following

| Method | Path                   | Auth | Description                   |
| ------ | ---------------------- | ---- | ----------------------------- |
| POST   | `/users/:id/follow`    | User | Follow a user                 |
| DELETE | `/users/:id/follow`    | User | Unfollow a user               |

### Friend Requests

| Method | Path                           | Auth | Description              |
| ------ | ------------------------------ | ---- | ------------------------ |
| POST   | `/users/:id/friend-request`    | User | Send friend request      |
| GET    | `/friend-requests`             | User | List incoming requests   |
| POST   | `/friend-requests/:id/accept`  | User | Accept request           |
| POST   | `/friend-requests/:id/decline` | User | Decline request          |
| DELETE | `/friend-requests/:id`         | User | Cancel sent request      |

### Friends

| Method | Path            | Auth | Description                   |
| ------ | --------------- | ---- | ----------------------------- |
| GET    | `/friends`      | User | List friends                  |
| DELETE | `/friends/:id`  | User | Remove friend                 |

---

## Resource: Activity & Feed

Base path: `/api/activities`, `/api/feed`, `/api/chart`

| Method | Path                   | Auth | Description                        |
| ------ | ---------------------- | ---- | ---------------------------------- |
| GET    | `/activities/:user_id` | User | Get user's activity history        |
| GET    | `/feed`                | User | Get personalized goal feed         |
| GET    | `/chart/:user_id`      | User | Get commitment chart data          |
| GET    | `/users/:id/stats`     | User | Get user statistics                |

**Chart Query Parameters:**

| Parameter | Type   | Default      | Description                    |
| --------- | ------ | ------------ | ------------------------------ |
| `year`    | number | Current year | Year for chart data (2020-2030)|

---

## WebSocket / Phoenix Channels

HeadsUp uses Phoenix Channels for real-time updates via LiveView.

### LiveView Socket

**Connection:** `wss://{domain}/live/websocket`

**Authentication:** Session-based (same session cookie as API)

### PubSub Topics

| Topic Pattern           | Description                         |
| ----------------------- | ----------------------------------- |
| `goal:{goal_id}`        | Goal updates, new posts             |
| `user:{user_id}`        | User notifications, activity        |
| `feed:{user_id}`        | Personalized feed updates           |

### LiveView Events

| Event              | Direction        | Description                    |
| ------------------ | ---------------- | ------------------------------ |
| `phx_join`         | client -> server | Join channel                   |
| `phx_leave`        | client -> server | Leave channel                  |
| `phx_reply`        | server -> client | Response to event              |
| `diff`             | server -> client | DOM update patch               |
| `live_redirect`    | server -> client | Navigation instruction         |

---

## Privacy & Authorization Rules

### Goal Privacy Levels

| Privacy        | View                    | Subscribe        | Like   |
| -------------- | ----------------------- | ---------------- | ------ |
| `public`       | Anyone                  | Any user         | Anyone |
| `friends_only` | Owner + Friends         | Friends only     | Anyone |
| `private`      | Owner only              | No one           | Anyone |

### Ownership Rules

- Users can only modify their own goals
- Users cannot like/subscribe to their own goals
- Admin can manage all categories
- Only owner can freeze/fail/restore goals

---

## Content Types

### Request

```
Content-Type: application/json
```

### Response

```
Content-Type: application/json; charset=utf-8
```

---

## CORS Configuration

Currently not configured for cross-origin requests. All API calls expected from same origin (LiveView frontend).

Future CORS headers for mobile app:

```
Access-Control-Allow-Origin: https://headsup.app
Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Allow-Credentials: true
```

---

## API Changelog

| Version | Date       | Changes                              |
| ------- | ---------- | ------------------------------------ |
| 1.0.0   | 2024-01-01 | Initial API with goals, categories   |
| 1.1.0   | 2024-02-01 | Added friend requests, following     |
| 1.2.0   | 2024-03-01 | Added activity feed, commitment chart|
