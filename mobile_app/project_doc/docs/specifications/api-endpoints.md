# API Endpoints

Complete reference for all HeadsUp API endpoints - **implemented** and **to be built**.

**Legend:**
- ✅ **Implemented** - Endpoint exists in router and is functional
- 🔨 **To Build** - Endpoint needed based on data model but not yet implemented

---

## Implementation Summary

| Resource              | Status | Endpoints Implemented | Endpoints Needed |
| --------------------- | ------ | --------------------- | ---------------- |
| Goals                 | ✅     | 14/14                 | 0                |
| Goal Phases           | 🔨     | 0/5                   | 5                |
| Goal Steps            | 🔨     | 0/7                   | 7                |
| Goal Posts            | 🔨     | 0/6                   | 6                |
| Reactions             | 🔨     | 0/2                   | 2                |
| Comments              | 🔨     | 0/5                   | 5                |
| Categories            | ✅     | 6/6                   | 0                |
| Challenges            | 🔨     | 0/12                  | 12               |
| Challenge Tasks       | 🔨     | 0/4                   | 4                |
| Coach Templates       | 🔨     | 0/8                   | 8                |
| Template Enrollments  | 🔨     | 0/4                   | 4                |
| User Following        | ✅     | 2/2                   | 0                |
| Friend Requests       | ✅     | 5/5                   | 0                |
| Friends               | ✅     | 2/2                   | 0                |
| Activity/Feed         | ✅     | 4/4                   | 0                |
| User Profile          | 🔨     | 0/5                   | 5                |
| User Levels/XP        | 🔨     | 0/3                   | 3                |

---

## Authentication

HeadsUp uses session-based authentication.

### Mobile Login ✅

```
POST /api/auth/login
Content-Type: application/json
```

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

### Current User ✅

```
GET /api/auth/me
Authorization: Required (session cookie)
```

### Mobile Logout ✅

```
DELETE /api/auth/logout
Authorization: Required (session cookie)
```

---

## Goals API ✅

All goal endpoints are implemented.

### List Public Goals ✅

```
GET /api/goals
```

**Query Parameters:**

| Parameter  | Type   | Default        | Description                    |
| ---------- | ------ | -------------- | ------------------------------ |
| `status`   | string | —              | Filter: active, completed, paused, cancelled, frozen, failed |
| `search`   | string | —              | Search in title/description    |
| `sort`     | string | `created_desc` | Sort order                     |
| `page`     | number | 1              | Page number                    |
| `per_page` | number | 20             | Items per page (max 100)       |

**Response:**

```json
{
  "goals": [
    {
      "id": 1,
      "title": "Learn Elixir",
      "description": "Short description",
      "big_description": "Detailed plan...",
      "status": "active",
      "privacy": "public",
      "progress": 45,
      "target_date": "2024-06-01T00:00:00Z",
      "image_path": "/uploads/goals/1/cover.jpg",
      "is_frozen": false,
      "user_id": 1,
      "group_id": 5,
      "inserted_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-20T14:22:00Z",
      "user": {
        "id": 1,
        "name": "John Doe",
        "user_name": "johndoe",
        "image_path": "/uploads/users/1/avatar.jpg"
      },
      "group": {
        "id": 5,
        "name": "Technology"
      },
      "likes_count": 12,
      "subscriptions_count": 8
    }
  ],
  "page": 1,
  "per_page": 20,
  "total": 150
}
```

### Get Single Goal ✅

```
GET /api/goals/:id
```

### Get Goals by Category ✅

```
GET /api/goals/category/:category_id
```

### Get My Goals ✅

```
GET /api/goals/my
Authorization: Required
```

### Get Deleted Goals ✅

```
GET /api/goals/deleted
Authorization: Required
```

### Create Goal ✅

```
POST /api/goals
Authorization: Required
Content-Type: application/json
```

**Request Body:**

```json
{
  "goal": {
    "title": "Learn Elixir",
    "description": "Short description",
    "big_description": "Full plan with details...",
    "group_id": 5,
    "privacy": "public",
    "target_date": "2024-06-01T00:00:00Z"
  }
}
```

**Business Rules:**
- Users can have max 2 active goals (free tier)
- `subscription_type: pro_3` allows 3 goals
- `subscription_type: pro_5` allows 5 goals
- `subscription_type: unlimited` allows unlimited goals

### Update Goal ✅

```
PUT /api/goals/:id
Authorization: Required (Owner only)
```

### Delete Goal (Soft Delete) ✅

```
DELETE /api/goals/:id
Authorization: Required (Owner only)
```

Sets `deleted_at` timestamp, does not permanently delete.

### Restore Goal ✅

```
POST /api/goals/:id/restore
Authorization: Required (Owner only)
```

### Like Goal ✅

```
POST /api/goals/:id/like
Authorization: Required
```

**Rules:** Cannot like own goal, cannot like twice.

### Unlike Goal ✅

```
DELETE /api/goals/:id/like
Authorization: Required
```

### Subscribe to Goal ✅

```
POST /api/goals/:id/subscribe
Authorization: Required
```

**Rules:** Cannot subscribe to own goal, respects privacy settings.

### Unsubscribe from Goal ✅

```
DELETE /api/goals/:id/subscribe
Authorization: Required
```

### Freeze Goal ✅

```
POST /api/goals/:id/freeze
Authorization: Required (Owner only)
```

Sets `is_frozen: true`, pauses goal.

### Unfreeze Goal ✅

```
POST /api/goals/:id/unfreeze
Authorization: Required (Owner only)
```

### Fail Goal ✅

```
POST /api/goals/:id/fail
Authorization: Required (Owner only)
Content-Type: application/json
```

**Request Body (Required):**

```json
{
  "reason": "Explanation for why the goal failed..."
}
```

Sets `status: failed`, `failure_reason`, and `failed_at` timestamp.

---

## Goal Phases API 🔨 TO BUILD

Based on data model: `goal_phases` table with `id`, `title`, `order_index`, `goal_id`.

Goals now have Phases, and Phases contain Steps: `Goal → Phase → Step`

### List Goal Phases 🔨

```
GET /api/goals/:goal_id/phases
Authorization: None (respects goal privacy)
```

**Response:**

```json
{
  "phases": [
    {
      "id": 1,
      "title": "Planning Phase",
      "order_index": 1,
      "goal_id": 1,
      "steps_count": 5,
      "completed_steps_count": 3,
      "inserted_at": "2024-01-15T10:30:00Z"
    },
    {
      "id": 2,
      "title": "Execution Phase",
      "order_index": 2,
      "goal_id": 1,
      "steps_count": 8,
      "completed_steps_count": 0,
      "inserted_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### Create Goal Phase 🔨

```
POST /api/goals/:goal_id/phases
Authorization: Required (Owner only)
Content-Type: application/json
```

**Request Body:**

```json
{
  "phase": {
    "title": "New Phase",
    "order_index": 3
  }
}
```

**Business Rules:**
- `order_index` defaults to next available
- At least 1 phase required per goal

### Update Goal Phase 🔨

```
PUT /api/goals/:goal_id/phases/:id
Authorization: Required (Owner only)
Content-Type: application/json
```

### Delete Goal Phase 🔨

```
DELETE /api/goals/:goal_id/phases/:id
Authorization: Required (Owner only)
```

**Rules:** Cannot delete if phase has steps. Delete steps first.

### Reorder Phases 🔨

```
PUT /api/goals/:goal_id/phases/reorder
Authorization: Required (Owner only)
Content-Type: application/json
```

**Request Body:**

```json
{
  "phase_ids": [2, 1, 3]
}
```

---

## Goal Steps API 🔨 TO BUILD

Based on data model: `goal_steps` table with `id`, `title`, `description`, `order_index`, `is_completed`, `completed_at`, `phase_id`.

**Note:** Steps now belong to Phases, not directly to Goals.

### List Phase Steps 🔨

```
GET /api/goals/:goal_id/phases/:phase_id/steps
Authorization: None (respects goal privacy)
```

**Response:**

```json
{
  "steps": [
    {
      "id": 1,
      "title": "Read official documentation",
      "description": "Go through the Getting Started guide",
      "is_completed": true,
      "completed_at": "2024-01-18T14:30:00Z",
      "order_index": 1,
      "phase_id": 1,
      "inserted_at": "2024-01-15T10:30:00Z"
    },
    {
      "id": 2,
      "title": "Complete first project",
      "description": null,
      "is_completed": false,
      "completed_at": null,
      "order_index": 2,
      "phase_id": 1,
      "inserted_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### Create Phase Step 🔨

```
POST /api/goals/:goal_id/phases/:phase_id/steps
Authorization: Required (Owner only)
Content-Type: application/json
```

**Request Body:**

```json
{
  "step": {
    "title": "Complete Elixir course",
    "description": "Finish the official Phoenix tutorial",
    "order_index": 3
  }
}
```

**Business Rules:**
- Maximum 20 steps per phase
- `order_index` defaults to next available

### Update Phase Step 🔨

```
PUT /api/goals/:goal_id/phases/:phase_id/steps/:id
Authorization: Required (Owner only)
Content-Type: application/json
```

**Request Body:**

```json
{
  "step": {
    "title": "Updated title",
    "description": "Updated description"
  }
}
```

### Delete Phase Step 🔨

```
DELETE /api/goals/:goal_id/phases/:phase_id/steps/:id
Authorization: Required (Owner only)
```

### Complete Step 🔨

```
POST /api/goals/:goal_id/phases/:phase_id/steps/:id/complete
Authorization: Required (Owner only)
```

**Side Effects:**
- Sets `is_completed: true` and `completed_at`
- Recalculates goal `progress` percentage
- Creates `UserActivity` with type `step_completed`
- Awards XP to user (+15 XP)

### Uncomplete Step 🔨

```
POST /api/goals/:goal_id/phases/:phase_id/steps/:id/uncomplete
Authorization: Required (Owner only)
```

### Reorder Steps 🔨

```
PUT /api/goals/:goal_id/phases/:phase_id/steps/reorder
Authorization: Required (Owner only)
Content-Type: application/json
```

**Request Body:**

```json
{
  "step_ids": [3, 1, 2, 4]
}
```

---

## Goal Posts API 🔨 TO BUILD

Based on data model: `goal_posts` table with `id`, `content`, `post_type`, `image_path`, `goal_id`, `user_id`, `step_id`.

### List Goal Posts 🔨

```
GET /api/goals/:goal_id/posts
Authorization: None (respects goal privacy)
```

**Query Parameters:**

| Parameter   | Type   | Default | Description                    |
| ----------- | ------ | ------- | ------------------------------ |
| `post_type` | string | —       | Filter: update, milestone, achievement, challenge, motivation |
| `page`      | number | 1       | Page number                    |
| `per_page`  | number | 20      | Items per page                 |

**Response:**

```json
{
  "posts": [
    {
      "id": 1,
      "content": "Just completed my first module!",
      "post_type": "achievement",
      "image_path": "/uploads/posts/1/image.jpg",
      "goal_id": 1,
      "user_id": 1,
      "step_id": 3,
      "inserted_at": "2024-01-21T16:45:00Z",
      "user": {
        "id": 1,
        "name": "John Doe",
        "user_name": "johndoe"
      },
      "step": {
        "id": 3,
        "title": "Complete first project"
      },
      "likes_count": 8
    }
  ],
  "page": 1,
  "per_page": 20,
  "total": 15
}
```

### Get Single Post 🔨

```
GET /api/goals/:goal_id/posts/:id
Authorization: None (respects goal privacy)
```

### Create Goal Post 🔨

```
POST /api/goals/:goal_id/posts
Authorization: Required (Owner only)
Content-Type: application/json
```

**Request Body:**

```json
{
  "post": {
    "content": "Made great progress today!",
    "post_type": "update",
    "step_id": 3,
    "image_path": "/uploads/posts/new/image.jpg"
  }
}
```

**Post Types (Enum):**
- `update` - General progress update
- `milestone` - Significant progress point
- `achievement` - Completed milestone
- `challenge` - Obstacles faced
- `motivation` - Inspirational content

**Side Effects:**
- Creates `UserActivity` with type `post_created`
- Awards XP to user
- Notifies subscribers

### Update Goal Post 🔨

```
PUT /api/goals/:goal_id/posts/:id
Authorization: Required (Owner only)
Content-Type: application/json
```

### Delete Goal Post 🔨

```
DELETE /api/goals/:goal_id/posts/:id
Authorization: Required (Owner only)
```

---

## Reactions API 🔨 TO BUILD

Based on data model: Polymorphic `reactions` table with `user_id`, `target_type`, `target_id`, `reaction_type`.

Replaces legacy `goal_likes` and `goal_post_likes` tables.

### Create Reaction 🔨

```
POST /api/reactions
Authorization: Required
Content-Type: application/json
```

**Request Body:**

```json
{
  "reaction": {
    "target_type": "goal",
    "target_id": 1,
    "reaction_type": "like"
  }
}
```

**Target Types:** `goal`, `post`, `comment`
**Reaction Types:** `like`, `dislike`

**Rules:**
- Cannot react to own content
- Cannot react to same target twice (update reaction instead)

**Response:**

```json
{
  "reaction": {
    "id": 1,
    "user_id": 5,
    "target_type": "goal",
    "target_id": 1,
    "reaction_type": "like",
    "inserted_at": "2024-01-21T14:30:00Z"
  }
}
```

**Side Effects:**
- Creates `UserActivity` with type `post_liked` for liker
- Creates `UserActivity` with type `post_received_like` for content author
- Awards XP to both users

### Delete Reaction 🔨

```
DELETE /api/reactions/:id
Authorization: Required
```

Or use convenience endpoints:

```
DELETE /api/goals/:id/reaction
DELETE /api/goals/:goal_id/posts/:post_id/reaction
DELETE /api/comments/:id/reaction
Authorization: Required
```

---

## Comments API 🔨 TO BUILD

Based on data model: Polymorphic `comments` table with `user_id`, `target_type`, `target_id`, `content`.

### List Comments 🔨

```
GET /api/goals/:goal_id/comments
GET /api/goals/:goal_id/posts/:post_id/comments
Authorization: None (respects content privacy)
```

**Query Parameters:**

| Parameter  | Type   | Default | Description        |
| ---------- | ------ | ------- | ------------------ |
| `page`     | number | 1       | Page number        |
| `per_page` | number | 20      | Items per page     |

**Response:**

```json
{
  "comments": [
    {
      "id": 1,
      "content": "Great progress! Keep it up!",
      "user_id": 5,
      "target_type": "goal",
      "target_id": 1,
      "inserted_at": "2024-01-21T16:45:00Z",
      "user": {
        "id": 5,
        "name": "Jane Doe",
        "user_name": "janedoe",
        "image_path": "/uploads/users/5/avatar.jpg"
      },
      "reactions_count": 3
    }
  ],
  "page": 1,
  "per_page": 20,
  "total": 8
}
```

### Create Comment 🔨

```
POST /api/goals/:goal_id/comments
POST /api/goals/:goal_id/posts/:post_id/comments
Authorization: Required
Content-Type: application/json
```

**Request Body:**

```json
{
  "comment": {
    "content": "This is really inspiring!"
  }
}
```

**Side Effects:**
- Creates `UserActivity` with type `comment_created`
- Awards XP (+5 XP)
- Notifies content owner

### Update Comment 🔨

```
PUT /api/comments/:id
Authorization: Required (Owner only)
Content-Type: application/json
```

### Delete Comment 🔨

```
DELETE /api/comments/:id
Authorization: Required (Owner only)
```

### React to Comment 🔨

```
POST /api/comments/:id/react
Authorization: Required
Content-Type: application/json
```

**Request Body:**

```json
{
  "reaction_type": "like"
}
```

---

## Challenges API 🔨 TO BUILD

Based on Feature 2: Challenges (Predefined + Custom with Scheduling).
Data model: `challenges`, `challenge_phases`, `challenge_steps`, `challenge_tasks`, `challenge_participants`.

### List Challenges 🔨

```
GET /api/challenges
Authorization: None
```

**Query Parameters:**

| Parameter   | Type   | Default | Description                    |
| ----------- | ------ | ------- | ------------------------------ |
| `type`      | string | —       | Filter: predefined, custom     |
| `category_id` | number | —     | Filter by category             |
| `visibility`| string | public  | Filter: public, friends        |
| `page`      | number | 1       | Page number                    |
| `per_page`  | number | 20      | Items per page                 |

**Response:**

```json
{
  "challenges": [
    {
      "id": 1,
      "title": "30-Day Consistency Challenge",
      "description": "Build a daily habit for 30 days",
      "type": "predefined",
      "visibility": "public",
      "category_id": 1,
      "creator_user_id": 1,
      "participants_count": 156,
      "phases_count": 3,
      "inserted_at": "2024-01-01T00:00:00Z",
      "category": {
        "id": 1,
        "name": "Fitness"
      },
      "creator": {
        "id": 1,
        "name": "Admin",
        "role": "admin"
      }
    }
  ],
  "page": 1,
  "per_page": 20,
  "total": 25
}
```

### Get Challenge Details 🔨

```
GET /api/challenges/:id
Authorization: None (respects visibility)
```

**Response includes:** Full challenge with phases, steps (for predefined) or tasks (for custom).

### Get My Challenges 🔨

```
GET /api/challenges/my
Authorization: Required
```

Returns challenges the user is participating in.

### Create Custom Challenge 🔨

```
POST /api/challenges
Authorization: Required
Content-Type: application/json
```

**Request Body:**

```json
{
  "challenge": {
    "title": "Morning Run Routine",
    "description": "Run every morning before work",
    "type": "custom",
    "category_id": 1,
    "visibility": "friends",
    "tasks": [
      {
        "title": "Run 3km",
        "schedule_type": "custom_weekdays",
        "schedule_weekdays": ["mon", "wed", "fri"]
      },
      {
        "title": "Stretch routine",
        "schedule_type": "daily"
      }
    ]
  }
}
```

**Schedule Types:**
- `daily` - Every day
- `twice_week` - Twice per week
- `every_other_day` - Alternating days
- `mon_fri` - Monday through Friday
- `custom_weekdays` - Specific days (requires `schedule_weekdays`)

**Business Rules:**
- Custom challenges count toward max 3 active items limit
- Users cannot edit predefined challenges

### Create Predefined Challenge (Admin) 🔨

```
POST /api/admin/challenges
Authorization: Required (Admin only)
Content-Type: application/json
```

**Request Body:**

```json
{
  "challenge": {
    "title": "30-Day Fitness Challenge",
    "description": "Transform your fitness in 30 days",
    "type": "predefined",
    "category_id": 1,
    "visibility": "public",
    "phases": [
      {
        "title": "Week 1: Foundation",
        "order_index": 1,
        "steps": [
          { "title": "Day 1: Baseline assessment", "order_index": 1 },
          { "title": "Day 2: Light cardio", "order_index": 2 }
        ]
      },
      {
        "title": "Week 2: Build Up",
        "order_index": 2,
        "steps": [
          { "title": "Day 8: Increase intensity", "order_index": 1 }
        ]
      }
    ]
  }
}
```

### Update Challenge 🔨

```
PUT /api/challenges/:id
Authorization: Required (Creator only for custom, Admin for predefined)
```

### Delete Challenge 🔨

```
DELETE /api/challenges/:id
Authorization: Required (Creator only for custom, Admin for predefined)
```

### Join Challenge 🔨

```
POST /api/challenges/:id/join
Authorization: Required
```

**Business Rules:**
- Active challenges count toward max 3 active items limit
- Creates `challenge_participant` record with status `enrolled`

**Response:**

```json
{
  "participant": {
    "id": 1,
    "challenge_id": 5,
    "user_id": 10,
    "status": "enrolled",
    "joined_at": "2024-01-21T10:00:00Z"
  }
}
```

**Side Effects:**
- Creates `UserActivity` with type `challenge_joined`
- Awards XP (+10 XP)

### Leave Challenge 🔨

```
DELETE /api/challenges/:id/leave
Authorization: Required
```

Sets participant status to `dropped`.

### Complete Challenge 🔨

```
POST /api/challenges/:id/complete
Authorization: Required
```

**Business Rules:**
- Only available when all phases/steps or tasks are completed
- Sets participant status to `completed`

**Side Effects:**
- Creates `UserActivity` with type `challenge_completed`
- Awards XP (+100 XP)

### Get Challenge Participants 🔨

```
GET /api/challenges/:id/participants
Authorization: None (respects visibility)
```

### Get Challenge Progress 🔨

```
GET /api/challenges/:id/progress
Authorization: Required (Participant only)
```

Returns user's progress on challenge steps/tasks.

---

## Challenge Tasks API 🔨 TO BUILD

For custom challenges with scheduled tasks.

### List Challenge Tasks 🔨

```
GET /api/challenges/:challenge_id/tasks
Authorization: None (respects challenge visibility)
```

### Create Challenge Task 🔨

```
POST /api/challenges/:challenge_id/tasks
Authorization: Required (Creator only, custom challenges only)
Content-Type: application/json
```

**Request Body:**

```json
{
  "task": {
    "title": "Meditation",
    "description": "10-minute morning meditation",
    "schedule_type": "daily"
  }
}
```

### Update Challenge Task 🔨

```
PUT /api/challenges/:challenge_id/tasks/:id
Authorization: Required (Creator only)
```

### Delete Challenge Task 🔨

```
DELETE /api/challenges/:challenge_id/tasks/:id
Authorization: Required (Creator only)
```

---

## Coach Center API 🔨 TO BUILD

Based on Feature 3: Coach Center (Group Goals + Dashboard).
Data model: `group_goal_templates`, `template_phases`, `template_steps`, `group_goal_enrollments`.

### List Coach Templates 🔨

```
GET /api/coach/templates
Authorization: Required (Coach role only)
```

Returns templates created by the current coach.

**Response:**

```json
{
  "templates": [
    {
      "id": 1,
      "title": "12-Week Fitness Transformation",
      "description": "Complete fitness program for beginners",
      "category_id": 1,
      "status": "active",
      "coach_user_id": 5,
      "enrolled_count": 24,
      "active_count": 18,
      "completed_count": 6,
      "inserted_at": "2024-01-01T00:00:00Z",
      "category": {
        "id": 1,
        "name": "Fitness"
      }
    }
  ]
}
```

### Get Template Details 🔨

```
GET /api/coach/templates/:id
Authorization: Required (Coach role, owner only)
```

**Response includes:** Full template with phases, steps, and enrollment statistics.

### Create Template 🔨

```
POST /api/coach/templates
Authorization: Required (Coach role only)
Content-Type: application/json
```

**Request Body:**

```json
{
  "template": {
    "title": "8-Week Running Program",
    "description": "From couch to 5K in 8 weeks",
    "category_id": 1,
    "status": "draft",
    "phases": [
      {
        "title": "Week 1-2: Building Base",
        "order_index": 1,
        "steps": [
          { "title": "Day 1: Walk/run intervals (20 min)", "order_index": 1 },
          { "title": "Day 2: Rest day", "order_index": 2 },
          { "title": "Day 3: Walk/run intervals (25 min)", "order_index": 3 }
        ]
      },
      {
        "title": "Week 3-4: Increasing Distance",
        "order_index": 2,
        "steps": [
          { "title": "Day 1: Run 10 minutes continuous", "order_index": 1 }
        ]
      }
    ]
  }
}
```

**Template Status:**
- `draft` - Not visible to participants
- `active` - Accepting enrollments
- `archived` - No new enrollments, existing continue

### Update Template 🔨

```
PUT /api/coach/templates/:id
Authorization: Required (Coach role, owner only)
```

**Rules:** Cannot edit phases/steps if participants have started.

### Delete Template 🔨

```
DELETE /api/coach/templates/:id
Authorization: Required (Coach role, owner only)
```

**Rules:** Cannot delete if active participants exist.

### Activate Template 🔨

```
POST /api/coach/templates/:id/activate
Authorization: Required (Coach role, owner only)
```

Sets status to `active`.

### Archive Template 🔨

```
POST /api/coach/templates/:id/archive
Authorization: Required (Coach role, owner only)
```

Sets status to `archived`.

### Get Template Participants 🔨

```
GET /api/coach/templates/:id/participants
Authorization: Required (Coach role, owner only)
```

**Response:**

```json
{
  "participants": [
    {
      "id": 1,
      "user": {
        "id": 10,
        "name": "John Doe",
        "user_name": "johndoe",
        "image_path": "/uploads/users/10/avatar.jpg"
      },
      "enrolled_at": "2024-01-15T10:00:00Z",
      "started_at": "2024-01-16T08:00:00Z",
      "participant_goal_id": 45,
      "progress": 35,
      "last_activity": "2024-01-20T14:30:00Z",
      "at_risk": false
    }
  ],
  "summary": {
    "total_enrolled": 24,
    "active": 18,
    "completed": 4,
    "at_risk": 2
  }
}
```

**At-Risk Indicator:** No activity in 7+ days.

---

## Template Enrollments API 🔨 TO BUILD

### Enroll Participant 🔨

```
POST /api/coach/templates/:template_id/enroll
Authorization: Required (Coach role, owner only)
Content-Type: application/json
```

**Request Body:**

```json
{
  "user_id": 10
}
```

Or bulk enroll:

```json
{
  "user_ids": [10, 11, 12, 13]
}
```

**Side Effects:**
- Creates `group_goal_enrollment` record
- Generates individual `goal` instance with phases/steps copied from template
- Links `participant_goal_id` to the generated goal

### Start Participant 🔨

```
POST /api/coach/templates/:template_id/enrollments/:id/start
Authorization: Required (Coach role, owner only)
```

Sets `started_at` timestamp, activates the participant's goal.

### Remove Participant 🔨

```
DELETE /api/coach/templates/:template_id/enrollments/:id
Authorization: Required (Coach role, owner only)
```

**Rules:** Can only remove before `started_at` is set.

### Get My Enrollments 🔨

```
GET /api/enrollments
Authorization: Required
```

Returns templates the current user is enrolled in (as a participant).

---

## Categories/Groups API ✅

All category endpoints are implemented.

### List All Categories ✅

```
GET /api/categories
```

### Get Category ✅

```
GET /api/categories/:id
```

### Get Subcategories ✅

```
GET /api/categories/:id/subcategories
```

### Create Category (Admin) ✅

```
POST /api/admin/categories
Authorization: Required (Admin only)
```

### Update Category (Admin) ✅

```
PUT /api/admin/categories/:id
Authorization: Required (Admin only)
```

### Delete Category (Admin) ✅

```
DELETE /api/admin/categories/:id
Authorization: Required (Admin only)
```

---

## User Following API ✅

Based on data model: `user_follows` table with `follower_id`, `following_id`.

### Follow User ✅

```
POST /api/users/:id/follow
Authorization: Required
```

**Rules:**
- Cannot follow yourself
- Cannot follow same user twice
- Respects user privacy settings

**Side Effects:**
- Creates `UserActivity` with type `user_followed`
- Creates `UserActivity` with type `user_received_follow` for target

### Unfollow User ✅

```
DELETE /api/users/:id/follow
Authorization: Required
```

---

## Friend Requests API ✅

Based on data model: `friendships` table with `user_id`, `friend_id`, `status`.

### Send Friend Request ✅

```
POST /api/users/:id/friend-request
Authorization: Required
```

**Rules:**
- Cannot friend yourself
- Cannot send duplicate requests
- Status starts as `pending`

### List Friend Requests ✅

```
GET /api/friend-requests
Authorization: Required
```

Returns incoming friend requests (where `friend_id` = current user).

### Accept Friend Request ✅

```
POST /api/friend-requests/:id/accept
Authorization: Required
```

Sets status to `accepted`, awards XP to both users.

### Decline Friend Request ✅

```
POST /api/friend-requests/:id/decline
Authorization: Required
```

Sets status to `declined`.

### Cancel Friend Request ✅

```
DELETE /api/friend-requests/:id
Authorization: Required
```

Deletes a pending request you sent.

---

## Friends API ✅

### List Friends ✅

```
GET /api/friends
Authorization: Required
```

Returns accepted friendships.

### Remove Friend ✅

```
DELETE /api/friends/:id
Authorization: Required
```

Deletes friendship record.

---

## Activity & Feed API ✅

Based on data model: `user_activities` table.

### Get User Activity ✅

```
GET /api/activities/:user_id
Authorization: Required
```

**Privacy:** Only returns activity for users you follow or are friends with.

### Get Personalized Feed ✅

```
GET /api/feed
Authorization: Required
```

Returns posts from subscribed goals, ordered by recency.

### Get Commitment Chart ✅

```
GET /api/chart/:user_id
Authorization: Required
```

Returns GitHub-style activity heatmap data.

### Get User Stats ✅

```
GET /api/users/:user_id/stats
Authorization: Required
```

---

## User Profile API 🔨 TO BUILD

Based on data model: `users` table fields that need update endpoints.

### Get User Profile 🔨

```
GET /api/users/:id
Authorization: None (respects privacy settings)
```

**Response:**

```json
{
  "user": {
    "id": 1,
    "user_name": "johndoe",
    "name": "John Doe",
    "bio": "Elixir enthusiast",
    "about": "Building cool stuff with Phoenix...",
    "level": 5,
    "image_path": "/uploads/users/1/avatar.jpg",
    "privacy": "public",
    "role": "user",
    "xp": 1250,
    "inserted_at": "2024-01-01T00:00:00Z",
    "goals_count": 2,
    "followers_count": 15,
    "following_count": 12
  }
}
```

**User Roles:** `guest`, `user`, `coach`, `admin`

### Update User Profile 🔨

```
PUT /api/users/me
Authorization: Required
Content-Type: application/json
```

**Request Body:**

```json
{
  "user": {
    "name": "John Smith",
    "bio": "Updated bio",
    "about": "Extended about section...",
    "image_path": "/uploads/users/1/new-avatar.jpg"
  }
}
```

### Update User Privacy 🔨

```
PUT /api/users/me/privacy
Authorization: Required
Content-Type: application/json
```

**Request Body:**

```json
{
  "privacy": "friends_only"
}
```

**Privacy Options:**
- `public` - Anyone can view profile and follow
- `private` - Only friends can view profile
- `friends_only` - Profile visible, but only friends can follow

### Get My Followers 🔨

```
GET /api/users/me/followers
Authorization: Required
```

### Get My Following 🔨

```
GET /api/users/me/following
Authorization: Required
```

---

## User Levels/XP API 🔨 TO BUILD

Based on data model: `user_levels` table with `level`, `xp`, `level_name`, `user_id`.

### Get User Level 🔨

```
GET /api/users/:id/level
Authorization: None
```

**Response:**

```json
{
  "level": {
    "level": 5,
    "xp": 1250,
    "level_name": "Dolphin",
    "xp_to_next_level": 250,
    "total_xp_for_next_level": 1500
  }
}
```

**Ocean-Themed Level Names:**

| Level | Name      | XP Required |
| ----- | --------- | ----------- |
| 1     | Seastar   | 0           |
| 2     | Crab      | 100         |
| 3     | Seahorse  | 300         |
| 4     | Turtle    | 600         |
| 5     | Dolphin   | 1000        |
| 6     | Seal      | 1500        |
| 7     | Orca      | 2100        |
| 8     | Whale     | 2800        |
| 9     | Kraken    | 3600        |
| 10    | Shark     | 4500        |

### Get Leaderboard 🔨

```
GET /api/leaderboard
Authorization: None
```

**Query Parameters:**

| Parameter | Type   | Default | Description                    |
| --------- | ------ | ------- | ------------------------------ |
| `type`    | string | `xp`    | Sort by: xp, level, streak     |
| `period`  | string | `all`   | Filter: all, month, week       |
| `limit`   | number | 10      | Number of users                |

**Response:**

```json
{
  "leaderboard": [
    {
      "rank": 1,
      "user": {
        "id": 5,
        "name": "Jane Doe",
        "user_name": "janedoe",
        "image_path": "/uploads/users/5/avatar.jpg"
      },
      "level": 8,
      "level_name": "Whale",
      "xp": 2850,
      "goals_completed": 12
    }
  ],
  "current_user_rank": 42
}
```

### Get XP History 🔨

```
GET /api/users/me/xp-history
Authorization: Required
```

**Response:**

```json
{
  "xp_events": [
    {
      "id": 1,
      "activity_type": "goal_completed",
      "xp_change": 100,
      "description": "Completed goal: Learn Elixir",
      "inserted_at": "2024-01-21T14:30:00Z"
    },
    {
      "id": 2,
      "activity_type": "post_liked",
      "xp_change": 5,
      "description": "Liked a post",
      "inserted_at": "2024-01-21T10:15:00Z"
    }
  ],
  "total_xp": 1250
}
```

---

## XP Rewards Reference

| Activity Type           | XP Reward |
| ----------------------- | --------- |
| `goal_created`          | +10       |
| `goal_completed`        | +100      |
| `goal_failed`           | -20       |
| `goal_step_completed`   | +15       |
| `post_created`          | +10       |
| `post_liked`            | +5        |
| `post_received_like`    | +3        |
| `user_followed`         | +5        |
| `user_received_follow`  | +3        |
| `friend_request_sent`   | +5        |
| `friend_request_accepted` | +10     |
| `daily_login`           | +5        |

---

## LiveView Routes Reference

### Public Pages ✅

| Route                    | LiveView Module             | Description           |
| ------------------------ | --------------------------- | --------------------- |
| `/`                      | PageController              | Home page             |
| `/goals`                 | GoalLive.Index              | Browse public goals   |
| `/goals/new`             | GoalLive.New                | Create goal           |
| `/goals/:id`             | GoalLive.Show               | View goal details     |
| `/goals-category`        | GoalCategoryLive.Index      | Browse categories     |
| `/goals-category/:id`    | GoalCategoryLive.Show       | View category         |
| `/all-goals`             | AllGoalsLive.Index          | All public goals      |
| `/people`                | UsersLive.Index             | Browse users          |
| `/people/:username`      | UsersLive.Show              | View user profile     |

### Auth Pages ✅

| Route                          | LiveView Module                    |
| ------------------------------ | ---------------------------------- |
| `/users/register`              | UserRegistrationLive               |
| `/users/log_in`                | UserLoginLive                      |
| `/users/reset_password`        | UserForgotPasswordLive             |
| `/users/reset_password/:token` | UserResetPasswordLive              |
| `/users/confirm`               | UserConfirmationInstructionsLive   |
| `/users/confirm/:token`        | UserConfirmationLive               |

### Authenticated Pages ✅

| Route                               | LiveView Module    |
| ----------------------------------- | ------------------ |
| `/goals/:id/edit`                   | GoalLive.Edit      |
| `/my-goals`                         | MyGoalsLive.Index  |
| `/connections`                      | ConnectionsLive.Index |
| `/feed`                             | FeedLive.Index     |
| `/users/settings`                   | UserSettingsLive   |

### Admin Pages ✅

| Route              | LiveView Module         |
| ------------------ | ----------------------- |
| `/admin/categories`| Admin.GroupsLive.Index  |

### Challenges Pages 🔨 TO BUILD

| Route                   | LiveView Module            | Description              |
| ----------------------- | -------------------------- | ------------------------ |
| `/challenges`           | ChallengeLive.Index        | Browse challenges        |
| `/challenges/new`       | ChallengeLive.New          | Create custom challenge  |
| `/challenges/:id`       | ChallengeLive.Show         | Challenge details        |
| `/challenges/:id/progress` | ChallengeLive.Progress  | My progress on challenge |
| `/my-challenges`        | MyChallengesLive.Index     | User's active challenges |

### Coach Pages 🔨 TO BUILD

| Route                             | LiveView Module                | Description              |
| --------------------------------- | ------------------------------ | ------------------------ |
| `/coach`                          | CoachLive.Dashboard            | Coach dashboard          |
| `/coach/templates`                | CoachLive.Templates.Index      | List templates           |
| `/coach/templates/new`            | CoachLive.Templates.New        | Create template          |
| `/coach/templates/:id`            | CoachLive.Templates.Show       | Template details         |
| `/coach/templates/:id/edit`       | CoachLive.Templates.Edit       | Edit template            |
| `/coach/templates/:id/participants` | CoachLive.Templates.Participants | Manage participants   |

---

## Error Responses

| HTTP Code | Error Type      | Example Message                         |
| --------- | --------------- | --------------------------------------- |
| 400       | Bad Request     | "Invalid request parameters"            |
| 401       | Unauthorized    | "You must be logged in"                 |
| 403       | Forbidden       | "You can only edit your own goals"      |
| 404       | Not Found       | "Goal not found"                        |
| 422       | Unprocessable   | `{ "errors": { "title": [...] } }`      |
| 500       | Server Error    | "An unexpected error occurred"          |

---

## What Needs To Be Built - Priority Order

### Phase 1: Goal Phases & Steps API (Critical)
Goals now have Phases, and Phases contain Steps. This is the core structure.

**Files to create:**
- `lib/heads_up/goals/goal_phase.ex`
- `lib/heads_up/goals/goal_step.ex` (update to reference phase_id)
- `lib/heads_up_web/controllers/api/phase_controller.ex`
- `lib/heads_up_web/controllers/api/phase_json.ex`
- `lib/heads_up_web/controllers/api/step_controller.ex`
- `lib/heads_up_web/controllers/api/step_json.ex`

**Router additions:**
```elixir
scope "/api/goals/:goal_id" do
  resources "/phases", PhaseController, except: [:new, :edit] do
    resources "/steps", StepController, except: [:new, :edit]
    post "/steps/:id/complete", StepController, :complete
    post "/steps/:id/uncomplete", StepController, :uncomplete
    put "/steps/reorder", StepController, :reorder
  end
  put "/phases/reorder", PhaseController, :reorder
end
```

### Phase 2: Goal Posts & Comments API (High Priority)
Posts enable social engagement around goals. Comments allow interaction.

**Files to create:**
- `lib/heads_up_web/controllers/api/post_controller.ex`
- `lib/heads_up_web/controllers/api/post_json.ex`
- `lib/heads_up_web/controllers/api/comment_controller.ex`
- `lib/heads_up_web/controllers/api/comment_json.ex`

**Router additions:**
```elixir
scope "/api/goals/:goal_id" do
  resources "/posts", PostController, except: [:new, :edit]
  resources "/comments", CommentController, only: [:index, :create]
end

scope "/api/goals/:goal_id/posts/:post_id" do
  resources "/comments", CommentController, only: [:index, :create]
end

scope "/api/comments" do
  put "/:id", CommentController, :update
  delete "/:id", CommentController, :delete
end
```

### Phase 3: Reactions API (High Priority)
Polymorphic likes/dislikes replacing legacy tables.

**Files to create:**
- `lib/heads_up/reactions.ex`
- `lib/heads_up/reactions/reaction.ex`
- `lib/heads_up_web/controllers/api/reaction_controller.ex`
- `lib/heads_up_web/controllers/api/reaction_json.ex`

**Router additions:**
```elixir
scope "/api" do
  post "/reactions", ReactionController, :create
  delete "/reactions/:id", ReactionController, :delete

  # Convenience endpoints
  delete "/goals/:id/reaction", ReactionController, :delete_goal_reaction
  delete "/goals/:goal_id/posts/:post_id/reaction", ReactionController, :delete_post_reaction
  delete "/comments/:id/reaction", ReactionController, :delete_comment_reaction
end
```

### Phase 4: Challenges API (MVP Feature)
Predefined and custom challenges with scheduling.

**Files to create:**
- `lib/heads_up/challenges.ex`
- `lib/heads_up/challenges/challenge.ex`
- `lib/heads_up/challenges/challenge_phase.ex`
- `lib/heads_up/challenges/challenge_step.ex`
- `lib/heads_up/challenges/challenge_task.ex`
- `lib/heads_up/challenges/challenge_participant.ex`
- `lib/heads_up_web/controllers/api/challenge_controller.ex`
- `lib/heads_up_web/controllers/api/challenge_json.ex`

**Router additions:**
```elixir
scope "/api/challenges" do
  get "/", ChallengeController, :index
  get "/my", ChallengeController, :my_challenges
  get "/:id", ChallengeController, :show
  post "/", ChallengeController, :create
  put "/:id", ChallengeController, :update
  delete "/:id", ChallengeController, :delete
  post "/:id/join", ChallengeController, :join
  delete "/:id/leave", ChallengeController, :leave
  post "/:id/complete", ChallengeController, :complete
  get "/:id/participants", ChallengeController, :participants
  get "/:id/progress", ChallengeController, :progress
end

scope "/api/challenges/:challenge_id/tasks" do
  get "/", TaskController, :index
  post "/", TaskController, :create
  put "/:id", TaskController, :update
  delete "/:id", TaskController, :delete
end

scope "/api/admin/challenges" do
  post "/", ChallengeController, :create_predefined
end
```

### Phase 5: Coach Center API (MVP Feature)
Group goal templates for coaches.

**Files to create:**
- `lib/heads_up/coaching.ex`
- `lib/heads_up/coaching/group_goal_template.ex`
- `lib/heads_up/coaching/template_phase.ex`
- `lib/heads_up/coaching/template_step.ex`
- `lib/heads_up/coaching/group_goal_enrollment.ex`
- `lib/heads_up_web/controllers/api/coach/template_controller.ex`
- `lib/heads_up_web/controllers/api/coach/template_json.ex`
- `lib/heads_up_web/controllers/api/coach/enrollment_controller.ex`

**Router additions:**
```elixir
scope "/api/coach/templates" do
  get "/", TemplateController, :index
  get "/:id", TemplateController, :show
  post "/", TemplateController, :create
  put "/:id", TemplateController, :update
  delete "/:id", TemplateController, :delete
  post "/:id/activate", TemplateController, :activate
  post "/:id/archive", TemplateController, :archive
  get "/:id/participants", TemplateController, :participants

  post "/:id/enroll", EnrollmentController, :enroll
  post "/:id/enrollments/:enrollment_id/start", EnrollmentController, :start
  delete "/:id/enrollments/:enrollment_id", EnrollmentController, :remove
end

scope "/api/enrollments" do
  get "/", EnrollmentController, :my_enrollments
end
```

### Phase 6: User Profile API (Medium Priority)
Profile management beyond settings.

**Router additions:**
```elixir
scope "/api/users" do
  get "/:id", UserController, :show
  put "/me", UserController, :update
  put "/me/privacy", UserController, :update_privacy
  get "/me/followers", UserController, :followers
  get "/me/following", UserController, :following
end
```

### Phase 7: Gamification API (Future)
XP, levels, and leaderboards.

**Router additions:**
```elixir
scope "/api" do
  get "/users/:id/level", LevelController, :show
  get "/leaderboard", LevelController, :leaderboard
  get "/users/me/xp-history", LevelController, :xp_history
end
```

---

## Testing

### cURL Examples

```bash
# Public: Get goals
curl http://localhost:4000/api/goals

# Public: Get single goal
curl http://localhost:4000/api/goals/1

# Authenticated: Get my goals (requires session cookie)
curl -b "_heads_up_key=SESSION_ID" http://localhost:4000/api/goals/my

# Authenticated: Create goal
curl -X POST http://localhost:4000/api/goals \
  -H "Content-Type: application/json" \
  -b "_heads_up_key=SESSION_ID" \
  -d '{"goal": {"title": "New Goal", "group_id": 1, "privacy": "public"}}'

# Authenticated: Like goal
curl -X POST http://localhost:4000/api/goals/1/like \
  -b "_heads_up_key=SESSION_ID"
```

### IEx Examples

```elixir
alias HeadsUp.{Goals, Accounts, Activities}
alias HeadsUp.Goals.{Goal, GoalStep, GoalPost}

# List public goals
Goals.list_public_goals()

# Get user's goals
user = Accounts.get_user!(1)
Goals.list_user_goals(user.id)

# Create activity
Activities.create_activity(%{
  user_id: 1,
  activity_type: :goal_created,
  xp_change: 10,
  goal_id: 1
})
```
