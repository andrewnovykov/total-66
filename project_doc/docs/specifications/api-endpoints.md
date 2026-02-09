# HeadsUp REST API Reference

Complete reference for all implemented API endpoints.

## Authentication

HeadsUp uses **Bearer token** authentication. Get a token via registration or login, then include it in all authenticated requests:

```
Authorization: Bearer <token>
```

Session-based authentication (via cookies) is also supported for web clients.

---

## Auth Endpoints

### Register

```
POST /api/auth/register
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123",
  "name": "John Doe",
  "user_name": "johndoe",
  "bio": "Optional bio"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": { "id": 1, "email": "user@example.com", "username": "johndoe", ... },
  "token": "Bearer-token-string"
}
```

### Login

```
POST /api/auth/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Logged in successfully",
  "data": { "id": 1, ... },
  "token": "Bearer-token-string"
}
```

### Get Current User

```
GET /api/auth/me
Authorization: Bearer <token>
```

### Logout

```
DELETE /api/auth/logout
Authorization: Bearer <token>
```

---

## Users API

### List Users (Public)

```
GET /api/users
```

**Query Parameters:** `page`, `per_page`

### Get User by ID (Public)

```
GET /api/users/:id
```

### Get User by Username (Public)

```
GET /api/users/username/:username
```

### Update Profile

```
PUT /api/users/me
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "user": {
    "name": "Updated Name",
    "bio": "New bio",
    "about": "Extended about section"
  }
}
```

### Get Followers

```
GET /api/users/:id/followers
Authorization: Bearer <token>
```

### Get Following

```
GET /api/users/:id/following
Authorization: Bearer <token>
```

### Follow User

```
POST /api/users/:id/follow
Authorization: Bearer <token>
```

### Unfollow User

```
DELETE /api/users/:id/follow
Authorization: Bearer <token>
```

### Send Friend Request

```
POST /api/users/:id/friend-request
Authorization: Bearer <token>
```

---

## Friend Requests API

### List Incoming Friend Requests

```
GET /api/friend-requests
Authorization: Bearer <token>
```

### Accept Friend Request

```
POST /api/friend-requests/:id/accept
Authorization: Bearer <token>
```

### Decline Friend Request

```
POST /api/friend-requests/:id/decline
Authorization: Bearer <token>
```

### Cancel Friend Request

```
DELETE /api/friend-requests/:id
Authorization: Bearer <token>
```

---

## Friends API

### List Friends

```
GET /api/friends
Authorization: Bearer <token>
```

### Remove Friend

```
DELETE /api/friends/:id
Authorization: Bearer <token>
```

---

## Goals API

### List Public Goals

```
GET /api/goals
```

**Query Parameters:** `status`, `search`, `sort`, `page`, `per_page`

### Get Goal by ID

```
GET /api/goals/:id
```

### Get Goals by Category

```
GET /api/goals/category/:category_id
```

### Get My Goals

```
GET /api/goals/my
Authorization: Bearer <token>
```

### Get Deleted Goals

```
GET /api/goals/deleted
Authorization: Bearer <token>
```

### Create Goal

```
POST /api/goals
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "goal": {
    "title": "Learn Elixir",
    "description": "Short description",
    "big_description": "Full plan...",
    "group_id": 5,
    "privacy": "public",
    "target_date": "2024-06-01T00:00:00Z"
  }
}
```

**Business Rules:** Max 2 goals (free), 3 (pro_3), 5 (pro_5), unlimited (unlimited)

### Update Goal

```
PUT /api/goals/:id
Authorization: Bearer <token> (Owner only)
```

### Delete Goal (Soft Delete)

```
DELETE /api/goals/:id
Authorization: Bearer <token> (Owner only)
```

### Restore Goal

```
POST /api/goals/:id/restore
Authorization: Bearer <token> (Owner only)
```

### Like / Unlike Goal

```
POST   /api/goals/:id/like
DELETE  /api/goals/:id/like
Authorization: Bearer <token>
```

### Subscribe / Unsubscribe

```
POST   /api/goals/:id/subscribe
DELETE  /api/goals/:id/subscribe
Authorization: Bearer <token>
```

### Freeze / Unfreeze Goal

```
POST /api/goals/:id/freeze
POST /api/goals/:id/unfreeze
Authorization: Bearer <token> (Owner only)
```

### Fail Goal

```
POST /api/goals/:id/fail
Authorization: Bearer <token> (Owner only)
```

**Request Body:**
```json
{ "reason": "Explanation for why the goal failed" }
```

---

## Goal Steps API

Nested under goals: `/api/goals/:goal_id/steps`

### List Steps

```
GET /api/goals/:goal_id/steps
Authorization: Bearer <token>
```

### Create Step

```
POST /api/goals/:goal_id/steps
Authorization: Bearer <token> (Goal owner only)
```

**Request Body:**
```json
{
  "step": {
    "title": "Complete Elixir course",
    "order": 3
  }
}
```

**Business Rules:** Max 20 steps per goal

### Update Step

```
PUT /api/goals/:goal_id/steps/:id
Authorization: Bearer <token> (Goal owner only)
```

### Delete Step

```
DELETE /api/goals/:goal_id/steps/:id
Authorization: Bearer <token> (Goal owner only)
```

### Toggle Step Completion

```
POST /api/goals/:goal_id/steps/:id/toggle
Authorization: Bearer <token> (Goal owner only)
```

---

## Goal Posts API

Nested under goals: `/api/goals/:goal_id/posts`

### List Posts

```
GET /api/goals/:goal_id/posts
Authorization: Bearer <token>
```

**Query Parameters:** `page`, `per_page`

### Create Post

```
POST /api/goals/:goal_id/posts
Authorization: Bearer <token> (Goal owner only)
```

**Request Body:**
```json
{
  "post": {
    "content": "Made great progress today!",
    "post_type": "update",
    "step_id": 3
  }
}
```

**Post Types:** `update`, `milestone`, `achievement`, `challenge`, `motivation`

### Update Post

```
PUT /api/goals/:goal_id/posts/:id
Authorization: Bearer <token> (Post owner only)
```

### Delete Post

```
DELETE /api/goals/:goal_id/posts/:id
Authorization: Bearer <token> (Post owner only)
```

### Like / Unlike Post

```
POST   /api/goals/:goal_id/posts/:id/like
DELETE  /api/goals/:goal_id/posts/:id/like
Authorization: Bearer <token>
```

---

## Post Comments API

### List Comments

```
GET /api/posts/:post_id/comments
Authorization: Bearer <token>
```

### Create Comment

```
POST /api/posts/:post_id/comments
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "comment": {
    "content": "Great progress!"
  }
}
```

### Delete Comment

```
DELETE /api/posts/:post_id/comments/:id
Authorization: Bearer <token> (Comment owner only)
```

---

## Challenges API

### List Challenges (Public)

```
GET /api/challenges
```

### List Templates (Public)

```
GET /api/challenges/templates
```

### List Challenge Categories (Public)

```
GET /api/challenges/categories
```

### Get Challenge Details (Public)

```
GET /api/challenges/:id
```

Returns full challenge with phases, steps, tasks, and participation info.

### Get My Challenges

```
GET /api/challenges/my
Authorization: Bearer <token>
```

### Create Challenge

```
POST /api/challenges
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "challenge": {
    "title": "Morning Run Routine",
    "description": "Run every morning",
    "type": "custom",
    "category_id": 1,
    "visibility": "public",
    "duration_days": 30,
    "is_template": false,
    "start_date": "2024-02-01",
    "end_date": "2024-03-02"
  }
}
```

### Update Challenge

```
PUT /api/challenges/:id
Authorization: Bearer <token> (Creator only)
```

### Delete Challenge

```
DELETE /api/challenges/:id
Authorization: Bearer <token> (Creator only)
```

### Start Challenge from Template

```
POST /api/challenges/:id/start
Authorization: Bearer <token>
```

**Optional Body:** `{ "start_date": "2024-02-01" }`

Creates a personal challenge from a template and auto-joins the user.

### Join Challenge

```
POST /api/challenges/:id/join
Authorization: Bearer <token>
```

### Leave Challenge

```
DELETE /api/challenges/:id/leave
Authorization: Bearer <token>
```

### Fail Challenge

```
POST /api/challenges/:id/fail
Authorization: Bearer <token> (Creator only)
```

**Request Body:** `{ "reason": "Explanation..." }`

### Share as Template

```
POST /api/challenges/:id/share
Authorization: Bearer <token> (Creator only)
```

Creates a public template from a personal challenge.

### Get Progress

```
GET /api/challenges/:id/progress
Authorization: Bearer <token> (Participant only)
```

### Get Today's Items

```
GET /api/challenges/:id/today
Authorization: Bearer <token> (Participant only)
```

### Get Challenge Feed

```
GET /api/challenges/:id/feed
Authorization: Bearer <token>
```

**Query Parameters:** `page`, `limit`

### Daily Check-in

```
POST /api/challenges/:id/check-in
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "check_in": {
    "note": "Good day overall",
    "mood": "good"
  }
}
```

**Moods:** `upset`, `neutral`, `good`

### Complete Step

```
POST /api/challenges/:id/steps/:step_id/complete
Authorization: Bearer <token>
```

### Complete Task

```
POST /api/challenges/:id/tasks/:task_id/complete
Authorization: Bearer <token>
```

---

## Check-in Interactions API

### Like / Unlike Check-in

```
POST   /api/check-ins/:id/like
DELETE  /api/check-ins/:id/like
Authorization: Bearer <token>
```

### Comment on Check-in

```
POST /api/check-ins/:id/comments
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "comment": {
    "content": "Keep it up!"
  }
}
```

---

## Categories API

### List Categories (Public)

```
GET /api/categories
```

### Get Category (Public)

```
GET /api/categories/:id
```

### Get Subcategories (Public)

```
GET /api/categories/:id/subcategories
```

### Create Category (Admin)

```
POST /api/admin/categories
Authorization: Bearer <token> (Admin only)
```

### Update Category (Admin)

```
PUT /api/admin/categories/:id
Authorization: Bearer <token> (Admin only)
```

### Delete Category (Admin)

```
DELETE /api/admin/categories/:id
Authorization: Bearer <token> (Admin only)
```

---

## Activity & Feed API

### Get User Activities

```
GET /api/activities/:user_id
Authorization: Bearer <token>
```

**Privacy:** Only returns activity for users you follow or are friends with.

### Get Personalized Feed

```
GET /api/feed
Authorization: Bearer <token>
```

### Get Commitment Chart

```
GET /api/chart/:user_id
Authorization: Bearer <token>
```

### Get User Stats

```
GET /api/users/:user_id/stats
Authorization: Bearer <token>
```

---

## Error Responses

All errors follow this format:

```json
{
  "success": false,
  "error": {
    "message": "Error description"
  }
}
```

Validation errors include details:

```json
{
  "success": false,
  "error": {
    "message": "Validation failed",
    "details": {
      "title": ["can't be blank"],
      "email": ["has already been taken"]
    }
  }
}
```

| HTTP Code | Meaning           | Example                                |
| --------- | ----------------- | -------------------------------------- |
| 200       | Success           | Operation completed                    |
| 201       | Created           | Resource created                       |
| 400       | Bad Request       | Invalid parameters                     |
| 401       | Unauthorized      | Missing or invalid token               |
| 403       | Forbidden         | Not allowed (not owner, not admin)     |
| 404       | Not Found         | Resource doesn't exist                 |
| 409       | Conflict          | Already exists (already joined, etc.)  |
| 422       | Unprocessable     | Validation failed                      |

---

## Route Summary (90 endpoints)

| Section                | Public | Auth | Total |
| ---------------------- | ------ | ---- | ----- |
| Auth                   | 2      | 2    | 4     |
| Users & Profile        | 3      | 8    | 11    |
| Friends & Requests     | —      | 7    | 7     |
| Goals (CRUD + Social)  | 3      | 16   | 19    |
| Goal Steps             | —      | 6    | 6     |
| Goal Posts             | —      | 7    | 7     |
| Post Comments          | —      | 3    | 3     |
| Challenges             | 3      | 15   | 18    |
| Check-in Interactions  | —      | 3    | 3     |
| Categories             | 3      | 3    | 6     |
| Activity & Feed        | —      | 4    | 4     |
| Groups (legacy)        | —      | 1    | 1     |
| **Total**              | **14** | **75** | **90** |
