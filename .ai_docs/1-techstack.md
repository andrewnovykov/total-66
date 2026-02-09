# HeadsUp - Tech Stack Analysis

## Core Technology Analysis

### Programming Language
- **Elixir**: ~> 1.14
- **Erlang/OTP**: Standard runtime (determined by Elixir version)

### Primary Framework
- **Phoenix**: ~> 1.7.21 (currently 1.7.14 in mix.exs, 1.7.21 in lock)
- **Phoenix LiveView**: ~> 1.0.0
- **Phoenix PubSub**: ~> 2.1.3

### Database and ORM
- **PostgreSQL**: Primary database
- **Ecto**: ~> 3.12.5
- **Ecto SQL**: ~> 3.12.1
- **Postgrex**: ~> 0.20.0

### Secondary Libraries
- **bcrypt_elixir**: ~> 3.0 (Password hashing)
- **Swoosh**: ~> 1.5 (Email delivery)
- **Finch**: ~> 0.13 (HTTP client for Swoosh)
- **Gettext**: ~> 0.20 (Internationalization)
- **Jason**: ~> 1.2 (JSON parsing)
- **Bandit**: ~> 1.5 (HTTP server, replacing Cowboy)

### State Management Approach
- **LiveView assigns**: Primary state management for UI state
- **Phoenix PubSub**: Real-time event broadcasting (configured as `HeadsUp.PubSub`)
- **Ecto Repo**: Data persistence layer
- No external state management (no Redis, ETS caching, or GenServer workers observed)

### Frontend Tooling
- **esbuild**: ~> 0.9 (version 0.17.11 in config)
- **Tailwind CSS**: ~> 0.3 (version 3.4.3 in config)
- **Heroicons**: v2.1.1 (from GitHub)
- No Alpine.js or other JavaScript frameworks observed

### Testing & Quality Tools
- **ExUnit**: Built-in testing framework
- **Floki**: ~> 0.37.1 (HTML parsing for tests)

### Telemetry & Monitoring
- **telemetry_metrics**: ~> 1.0
- **telemetry_poller**: ~> 1.0
- **Phoenix Live Dashboard**: ~> 0.8.3 (dev only)

---

## Domain Specificity Analysis

### Problem Domain
**Social Media Goal Tracking Platform** - A community-oriented application where users create personal goals, track progress through steps, share updates via posts, and engage socially through likes, subscriptions, follows, and friendships.

### Core Business/Domain Concepts

1. **Goal Management**
   - Goals with title, description, status (active/completed/paused/cancelled/frozen/failed/deleted)
   - Privacy levels (public/private/friends)
   - Goal steps (up to 20 per goal) with order and completion tracking
   - Goal freezing/unfreezing and soft deletion/restoration
   - Failure tracking with required failure reason

2. **Social Engagement**
   - Goal likes and subscriptions
   - Goal posts with types (update/milestone/achievement/challenge/motivation)
   - Post likes with ownership protection (can't like own content)
   - Comments on posts

3. **User Relationships**
   - User follows (follower/following pattern)
   - Friendships with request/accept/decline workflow
   - Privacy-aware follow system (respects user privacy settings)

4. **Gamification & Activity Tracking**
   - XP rewards for various activities
   - Ocean-themed level system (Seastar → Legendary Shark, 40 levels)
   - Activity tracking for all user actions
   - Commitment charts (GitHub-style activity visualization)
   - Streak tracking (current and longest)

5. **Groups/Categories**
   - Hierarchical group structure with parent_id
   - Goals belong to groups

### User Interaction Types
- **Real-time forms**: Goal creation/editing, post creation
- **Live updates**: Activity feeds, commitment charts
- **Social interactions**: Follow/unfollow, like/unlike, subscribe/unsubscribe
- **Navigation**: Multi-page LiveView application with authenticated and public routes

### Primary Data Types and Structures

**Core Ecto Schemas:**
- `HeadsUp.Users` - User accounts with XP, level, privacy settings
- `HeadsUp.Goal` - Goals with ownership, status, privacy
- `HeadsUp.GoalStep` - Ordered steps within goals
- `HeadsUp.Goals.GoalPost` - Social posts on goals
- `HeadsUp.GoalLike` - Goal like relationships
- `HeadsUp.GoalSubscription` - Goal subscription relationships
- `HeadsUp.GoalPostLike` - Post like relationships
- `HeadsUp.UserFollow` - User follow relationships
- `HeadsUp.Friendship` - Friend request/acceptance tracking
- `HeadsUp.UserActivity` - Activity logging for XP and feed
- `HeadsUp.UserLevel` - User level progression tracking
- `HeadsUp.Group` - Goal categories/groups

---

## Elixir/Phoenix Specific Patterns

### Phoenix Contexts Structure
The application uses bounded contexts with clear domain separation:

1. **`HeadsUp.Goals`** - Primary context for goal operations
   - Goal CRUD with ownership checks
   - Goal steps management
   - Post management with ownership
   - Social interactions (likes, subscriptions)
   - Activity tracking integration

2. **`HeadsUp.Accounts`** - User relationship context
   - User CRUD operations
   - Follow/unfollow functionality
   - Friendship management (request, accept, decline)
   - Privacy-aware operations

3. **`HeadsUp.Auth`** - Authentication context (phx.gen.auth generated)
   - User tokens
   - Password management
   - Email confirmation

4. **`HeadsUp.ActivityService`** - XP and leveling service
   - Activity tracking
   - XP reward calculations
   - Level progression
   - Streak calculations

5. **`HeadsUp.FeedService`** - Social feed service
   - Activity feed generation
   - Commitment chart data
   - Trending activities

6. **`HeadsUp.Groups`** - Category management context

### LiveView Patterns

**Mount Pattern:**
- Uses `on_mount` hooks for authentication (`HeadsUpWeb.UserAuth`)
- Admin routes use additional `HeadsUpWeb.AdminAuth` hook
- `mount_current_user` for public pages, `ensure_authenticated` for protected

**LiveView Organization:**
```
lib/heads_up_web/live/
├── goal_live/
│   ├── index.ex, show.ex, edit.ex, new.ex
│   └── form_component.ex
├── users_live/
│   ├── index.ex, show.ex
├── feed_live/
│   └── index.ex
├── admin/groups_live/
│   └── index.ex
└── [auth-related LiveViews]
```

**Function Components:**
- `HeadsUpWeb.CoreComponents` - Standard Phoenix generated components
- `HeadsUpWeb.Components.GoalCard` - Custom goal card component
- `HeadsUpWeb.Components.CommitmentChart` - Activity chart component

### PubSub Usage
- Configured as `HeadsUp.PubSub` in endpoint
- Used for LiveView real-time features
- Standard Phoenix PubSub pattern

### Background Job Processing
- No Oban or dedicated background job processor observed
- Activity tracking happens synchronously in transactions
- Potential area for future optimization

### Caching Strategies
- No explicit caching layer (no Cachex, ETS tables, or ConCache)
- Relies on database queries and LiveView state

---

## Application Boundaries

### Features Clearly Within Scope

1. **Goal Management**
   - CRUD operations with ownership validation
   - Step-based progress tracking
   - Status transitions (active, frozen, failed, completed)
   - Privacy controls

2. **Social Features**
   - Post creation and interaction
   - Goal likes and subscriptions
   - User follows and friendships
   - Activity feeds

3. **Gamification**
   - XP rewards for all tracked activities
   - 40-level progression system
   - Activity tracking and streaks

4. **API Layer**
   - JSON API for goals, users, categories
   - Authenticated and public endpoints
   - RESTful design

### Architecturally Inconsistent Features (to avoid)

1. **Real-time Collaboration**
   - No WebSocket channels for live editing
   - Single-user ownership model throughout

2. **File Storage/Uploads**
   - `image_path` fields exist but no upload handling observed
   - Would need LiveView uploads or external storage integration

3. **External API Integrations**
   - No OAuth, external API clients, or webhooks
   - Self-contained application

4. **Complex Caching**
   - No caching infrastructure in place
   - Adding would require architectural consideration

5. **Background Processing**
   - No job queue system
   - Adding Oban would be a significant addition

### Specialized Patterns Suggesting Domain Constraints

1. **Ownership Pattern**: All mutable operations validate `user_id` ownership
2. **Soft Delete Pattern**: Goals use `deleted_at` timestamps
3. **Status State Machine**: Goals have defined status transitions
4. **Privacy-Aware Queries**: Social features respect privacy settings
5. **Activity Tracking**: All significant actions are logged for gamification

---

## Summary

HeadsUp is a social media goal tracking platform built on a modern Elixir/Phoenix stack with LiveView for real-time UI. The architecture follows Phoenix best practices with bounded contexts, ownership-based authorization, and a gamification layer. The domain model centers around goals, social engagement, and user progression through an XP/level system. Future additions should maintain the ownership pattern, respect privacy settings, and integrate with the activity tracking system for gamification consistency.
