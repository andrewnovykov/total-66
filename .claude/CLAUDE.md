# HeadsUp - Social Media Goal Tracking Platform

## Project Overview

HeadsUp is a social media platform built with Phoenix, Elixir, and LiveView focused on goal creation, tracking, and community support. Users can create goals, break them down into actionable steps, share progress through posts, and build a supportive community around achievement.

## Technology Stack

- **Backend**: Phoenix Framework with Elixir
- **Frontend**: Phoenix LiveView
- **Database**: PostgreSQL with Ecto
- **CSS**: Mobile-first approach with Tailwind CSS
- **Real-time**: Phoenix PubSub for live updates

## User Types & Permissions

### 1. Guest Users
**Capabilities:**
- View public pages only
- Browse public goals and categories
- Read public goal posts and comments
- No interaction capabilities (like, comment, subscribe)

### 2. Registered Users
**Profile Management:**
- Change profile information
- Remove account
- Change avatar/profile picture
- Update password

**Goal Management:**
- Create maximum 2 goals
- Edit owned goals
- Delete owned goals
- Put goals on hold (pause)
- Change goal visibility (public/private/friends-only)
- Set goal categories and target dates

**Goal Steps:**
- Add up to 20 steps per goal
- Edit step details and target dates
- Track step completion
- Create posts related to specific steps

**Social Features:**
- Subscribe to other users' public goals
- Subscribe to friends' goals (if visibility = friends)
- Like public goals (even if private)
- Create goal feed posts with different types
- Edit own posts
- Comment on public goal posts
- Access personalized feed page with subscribed content

**Post Types Available:**
- Update (general progress)
- Achievement (completed milestone)
- Milestone (significant progress)
- Challenge (obstacles faced)
- Motivation (inspirational content)

### 3. Admin Users
**User Management:**
- View all users
- Block/unblock users
- Create new users
- Access user analytics

**Content Management:**
- Create goal categories
- Manage site-wide content
- Monitor platform activity

**Full Platform Access:**
- All registered user capabilities
- Override permissions when necessary

## Core Data Models

### User Schema
```elixir
schema "users" do
  field :name, :string
  field :user_name, :string, unique: true
  field :email, :string, unique: true
  field :bio, :string
  field :about, :string
  field :level, :integer, default: 1
  field :image_path, :string
  field :goal_amount, :integer, default: 0
  field :role, Ecto.Enum, values: [:guest, :user, :admin], default: :user
  field :status, Ecto.Enum, values: [:active, :blocked], default: :active
  
  has_many :goals, Goal
  has_many :goal_posts, GoalPost
  has_many :friendships, Friendship
  # ... other associations
end
```

### Goal Schema
```elixir
schema "goals" do
  field :title, :string
  field :small_description, :string
  field :description, :text  # big text description
  field :status, Ecto.Enum, values: [:active, :completed, :paused, :cancelled]
  field :privacy, Ecto.Enum, values: [:public, :private, :friends_only]
  field :target_date, :utc_datetime
  field :progress, :integer, default: 0
  field :image_path, :string
  field :plan, :text  # overall plan description
  
  belongs_to :user, User
  belongs_to :category, GoalCategory
  has_many :goal_steps, GoalStep
  has_many :goal_posts, GoalPost
  has_many :goal_likes, GoalLike
  has_many :goal_subscriptions, GoalSubscription
end
```

### GoalStep Schema
```elixir
schema "goal_steps" do
  field :title, :string
  field :description, :text
  field :target_date, :utc_datetime
  field :completed, :boolean, default: false
  field :order, :integer
  
  belongs_to :goal, Goal
  has_many :step_posts, GoalPost, where: [related_to: :step]
end
```

### GoalPost Schema
```elixir
schema "goal_posts" do
  field :content, :text
  field :post_type, Ecto.Enum, values: [:update, :milestone, :achievement, :challenge, :motivation]
  field :image_path, :string
  field :related_to, Ecto.Enum, values: [:goal, :step], default: :goal
  
  belongs_to :goal, Goal
  belongs_to :goal_step, GoalStep, null: true
  belongs_to :user, User
  has_many :comments, GoalComment
end
```

### GoalComment Schema
```elixir
schema "goal_comments" do
  field :content, :text
  
  belongs_to :goal_post, GoalPost
  belongs_to :user, User
end
```

### Friendship Schema
```elixir
schema "friendships" do
  field :status, Ecto.Enum, values: [:pending, :accepted, :declined, :blocked]

  belongs_to :user, User
  belongs_to :friend, User
end
```

### Challenge Schema
```elixir
schema "challenges" do
  field :title, :string
  field :description, :string
  field :type, Ecto.Enum, values: [:predefined, :custom]
  field :status, Ecto.Enum, values: [:active, :completed, :paused, :cancelled, :failed]
  field :is_template, :boolean, default: false
  field :duration_days, :integer
  field :start_date, :date
  field :end_date, :date
  field :template_id, :integer

  belongs_to :user, User
  belongs_to :category, ChallengeCategory
  has_many :phases, ChallengePhase
  has_many :participants, ChallengeParticipant
  has_many :daily_check_ins, DailyCheckIn
  has_many :derived_challenges, Challenge, foreign_key: :template_id
end
```

## Key Features Implementation

### Active Item Limits (BusinessRules)
- **Admin**: Unlimited active goals/challenges
- **Pro users** (pro_3, pro_5, unlimited subscription): 10 active goals/challenges
- **Free users**: 3 active goals/challenges
- **Step Limit**: Maximum 20 steps per goal
- **Validation**: Enforced via `HeadsUp.BusinessRules.can_create_active_item?/1`

### Privacy & Visibility System
1. **Public**: Anyone can view and subscribe
2. **Private**: Only owner can view, others can like but not subscribe
3. **Friends Only**: Friends can view and subscribe, others see limited info

### Subscription Logic
```elixir
def can_subscribe_to_goal?(current_user, goal) do
  case goal.privacy do
    :public -> true
    :private -> false
    :friends_only -> are_friends?(current_user, goal.user)
  end
end
```

### Feed Algorithm
- Show posts from subscribed goals
- Order by recency and engagement
- Filter by post types (optional)
- Paginate for performance

## Database Design

### Environment Configuration

The application uses **three separate databases** for different environments:

#### 1. Development Database
- **Name**: `heads_up_dev`
- **Purpose**: Local development and feature testing
- **Configuration**: `config/dev.exs`
- **Characteristics**:
  - Relaxed constraints for rapid development
  - Comprehensive seed data for testing
  - Debug logging enabled
  - Migration rollbacks allowed

#### 2. Testing Database
- **Name**: `heads_up_test`
- **Purpose**: Automated testing and CI/CD
- **Configuration**: `config/test.exs`
- **Characteristics**:
  - Fast reset between test runs
  - Sandbox mode for isolated tests
  - Minimal seed data
  - Optimized for speed over features

#### 3. Production Database
- **Name**: `heads_up_prod`
- **Purpose**: Live application serving real users
- **Configuration**: `config/prod.exs`
- **Characteristics**:
  - Strict constraints and validations
  - Performance optimizations
  - Backup and recovery systems
  - Connection pooling
  - SSL enforcement

### Database Environment Setup

```elixir
# config/dev.exs
config :heads_up, HeadsUp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "heads_up_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# config/test.exs
config :heads_up, HeadsUp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "heads_up_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# config/prod.exs
config :heads_up, HeadsUp.Repo,
  # Database URL from environment variable
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true,
  ssl_opts: [verify: :verify_none]
```

### Core Tables
1. `users` - User accounts and profiles
2. `goal_categories` - Admin-managed categories
3. `goals` - Main goal entities
4. `goal_steps` - Goal breakdown steps
5. `goal_posts` - Social posts about goals/steps
6. `goal_comments` - Comments on posts
7. `goal_likes` - Like tracking
8. `goal_subscriptions` - Subscription tracking
9. `friendships` - User relationships

### Indexes for Performance
```sql
CREATE INDEX idx_goals_user_id ON goals(user_id);
CREATE INDEX idx_goals_category_privacy ON goals(category_id, privacy);
CREATE INDEX idx_goal_posts_goal_date ON goal_posts(goal_id, inserted_at DESC);
CREATE INDEX idx_goal_subscriptions_user ON goal_subscriptions(user_id);
CREATE INDEX idx_friendships_status ON friendships(user_id, status);
```

## LiveView Pages Structure

```
/
├── AuthLive (login/register)
├── HomeLive (dashboard/feed)
├── GoalLive
│   ├── Index (user's goals)
│   ├── Show (goal detail + feed)
│   ├── New (create goal)
│   └── Edit (edit goal)
├── CategoryLive
│   ├── Index (browse categories)
│   └── Show (goals in category)
├── ChallengeLive
│   ├── Index (challenge listing, 2-col grid with stats)
│   ├── Show (challenge/template detail + start + check-ins)
│   ├── New (create challenge)
│   ├── Edit (edit challenge)
│   └── MyChallenges (user's active challenges)
├── ConnectionsLive (following/followers/friends/requests tabs)
├── FeedLive (personalized feed)
├── AllGoalsLive (browse all public goals)
├── ProfileLive
│   ├── Show (user profile + avatar upload)
│   └── Edit (edit profile)
└── AdminLive
    ├── Users (user management)
    ├── Categories (category management)
    ├── ChallengeCategoriesLive (challenge category management)
    └── Analytics (platform stats)
```

## Seed Data Requirements

Generate comprehensive seed data with:

### Quantities
- **100+ Users** (mix of regular users and admins)
- **100+ Goal Categories** (fitness, career, education, etc.)
- **100+ Goals** (distributed across users and categories)
- **2000+ Goal Steps** (20 steps per goal average)
- **500+ Goal Posts** (mix of all post types)
- **1000+ Comments** (engagement on posts)
- **Relationships** (friendships, subscriptions, likes)

### Realistic Data Patterns
- Users with 0-2 goals (enforcing limit)
- Goals with 1-20 steps
- Posts related to both goals and steps
- Privacy settings distribution (70% public, 20% friends, 10% private)
- Engagement patterns (likes, comments, subscriptions)

## Mobile-First CSS Approach

### Responsive Design Principles
```css
/* Mobile First - Base styles for mobile */
.goal-card {
  @apply w-full p-4 rounded-lg;
}

/* Tablet */
@media (min-width: 768px) {
  .goal-card {
    @apply p-6;
  }
}

/* Desktop */
@media (min-width: 1024px) {
  .goal-card {
    @apply p-8 max-w-4xl mx-auto;
  }
}
```

### Key UI Components
- Responsive navigation
- Card-based layouts
- Touch-friendly buttons
- Optimized forms
- Image galleries
- Infinite scroll feeds

## Development Commands

### Essential Mix Commands

#### Database Operations (Environment-Specific)
```bash
# Development database
MIX_ENV=dev mix ecto.create
MIX_ENV=dev mix ecto.migrate
MIX_ENV=dev mix ecto.reset
MIX_ENV=dev mix run priv/repo/seeds.exs

# Testing database
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
MIX_ENV=test mix ecto.reset

# Production database
MIX_ENV=prod mix ecto.create
MIX_ENV=prod mix ecto.migrate
# Note: Never reset production database!

# Default (development) environment
mix ecto.create          # Creates heads_up_dev
mix ecto.migrate         # Runs migrations on heads_up_dev
mix ecto.reset           # Drops, creates, migrates heads_up_dev
mix run priv/repo/seeds.exs  # Seeds heads_up_dev
```

#### Development Server
```bash
# Start development server (uses heads_up_dev database)
mix phx.server

# Start with IEx console
iex -S mix phx.server
```

#### Testing
```bash
# Run tests (uses heads_up_test database)
mix test
mix test.watch

# Run specific test file
mix test test/path/to/test_file.exs

# Run tests with coverage
mix test --cover
```

#### Code Quality
```bash
mix format
mix credo
mix dialyzer
```

#### Database Management Per Environment
```bash
# Check database status
mix ecto.migrations        # Shows migration status
MIX_ENV=test mix ecto.migrations
MIX_ENV=prod mix ecto.migrations

# Rollback migrations
mix ecto.rollback           # Development
MIX_ENV=test mix ecto.rollback --step 2
# Never rollback production without careful planning!

# Generate new migration
mix ecto.gen.migration migration_name
```

### Useful Development Queries
```elixir
# Check user goal count
user = Repo.get(User, 1) |> Repo.preload(:goals)
length(user.goals)

# Get user feed
HeadsUp.Goals.get_user_feed(user_id)

# Check friendship status
HeadsUp.Users.friendship_status(user1_id, user2_id)
```

## Testing Strategy

### Test Coverage Areas
1. **User Authentication & Authorization**
2. **Goal CRUD Operations with Limits**
3. **Privacy & Visibility Logic**
4. **Subscription & Like Functionality**
5. **Feed Generation Algorithm**
6. **Admin Capabilities**
7. **Mobile Responsiveness**

### LiveView Testing
```elixir
test "user can create goal up to limit", %{conn: conn} do
  user = user_fixture()
  {:ok, view, _html} = live(conn, Routes.goal_index_path(conn, :index))
  
  # Test goal creation limit
  assert view |> element("a", "New Goal") |> render_click()
  # ... test implementation
end
```

## Performance Considerations

### Database Optimizations
- Proper indexing strategy
- Pagination for feeds and lists
- Preloading associations efficiently
- Query optimization for complex feeds

### LiveView Performance
- Minimize DOM updates
- Use temporary assigns for large datasets
- Implement proper error boundaries
- Optimize image loading

### Caching Strategy
- Cache popular goal categories
- Cache user permissions
- Cache feed data temporarily
- Use ETS for session data

## Security Measures

### Authentication
- Secure password hashing (bcrypt)
- Session management
- CSRF protection
- Rate limiting on sensitive actions

### Authorization
- Role-based access control
- Resource-level permissions
- Privacy setting enforcement
- Admin privilege separation

### Data Protection
- Input sanitization
- SQL injection prevention
- XSS protection
- File upload security

## Deployment Considerations

### Production Environment Setup

#### Database Configuration
- **Production Database**: `heads_up_prod` with strict constraints
- **Environment Variables**: Database URL, pool size, SSL configuration
- **Connection Pooling**: Optimized for production load
- **SSL/TLS**: Enforced for all database connections
- **Backup Strategy**: Automated daily backups with point-in-time recovery

#### Environment Management
```bash
# Environment variables for production
export DATABASE_URL="postgresql://user:pass@host:5432/heads_up_prod"
export POOL_SIZE="20"
export SECRET_KEY_BASE="your-secret-key"
export PHX_HOST="yourdomain.com"
export PORT="4000"

# Deploy production
MIX_ENV=prod mix deps.get --only prod
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix phx.gen.release
MIX_ENV=prod mix release
```

#### Database Migration Strategy
```bash
# Production deployment steps
1. MIX_ENV=prod mix ecto.migrate    # Apply new migrations
2. MIX_ENV=prod mix phx.server      # Start application
3. Monitor logs and performance     # Verify deployment
```

### Environment Separation Best Practices

#### Development Environment
- **Database**: `heads_up_dev`
- **Purpose**: Feature development and local testing
- **Data**: Rich seed data for comprehensive testing
- **Logging**: Verbose for debugging

#### Testing Environment  
- **Database**: `heads_up_test`
- **Purpose**: Automated testing and CI/CD
- **Data**: Minimal, fast-reset data
- **Isolation**: Each test run uses fresh database state

#### Production Environment
- **Database**: `heads_up_prod`
- **Purpose**: Live user-facing application
- **Data**: Real user data with strict data protection
- **Performance**: Optimized for speed and reliability

### Monitoring & Maintenance

#### Application Performance Monitoring
- Database query performance tracking
- Response time monitoring
- Error rate tracking
- User session monitoring

#### Database Monitoring
- Connection pool utilization
- Query performance analysis
- Storage usage tracking
- Backup verification

#### Security Monitoring
- SSL certificate expiration tracking
- Database access logging
- Failed authentication attempts
- Data access audit trails

### Backup & Recovery Strategy

#### Automated Backups
```bash
# Daily production backup
pg_dump -h hostname -U username heads_up_prod > backup_$(date +%Y%m%d).sql

# Point-in-time recovery setup
wal_level = replica
archive_mode = on
archive_command = 'cp %p /backup/archive/%f'
```

#### Environment Data Management
- **Production**: Never copy to other environments
- **Development**: Regular refresh from sanitized production subset
- **Testing**: Automated reset between test runs

## Development Roadmap

A comprehensive development roadmap has been created in `/roadmap/ROADMAP.md` that outlines the future development phases:

### Phase Overview
1. **Security & Ownership Controls** - Goal/post ownership, freezing, deletion, failure system
2. **Spam Reporting & Moderation** - Red flag system, auto-moderation, admin review
3. **Admin Dashboard** - Analytics, content moderation, user management, group creation
4. **Social Following System** - User/group following, privacy controls, social feed
5. **Online Status & Real-time Features** - Live status indicators, real-time notifications
6. **Challenges System** - Template challenges, daily tasks, recurrence patterns
7. **Gamification & Level System** - XP system, ocean-themed levels, level penalties
8. **Activity Tracking & Analytics** - Commitment charts, personal analytics, activity heatmaps

### Key Upcoming Features
- **Ownership Controls**: Only goal owners can edit their goals and posts
- **Goal Management**: Freeze/unfreeze, soft delete, failure with reasons
- **Spam Reporting**: Red flag icons on goals/posts, 3-strike auto-hide system
- **Admin Dashboard**: Complete platform management with analytics and moderation
- **Social Features**: Follow users/groups, private profiles, friend requests
- **Online Status**: Real-time green/red dot indicators using Phoenix channels
- **Challenge System**: Template-based challenges with daily tasks and recurrence
- **Level System**: Ocean-themed progression (Seastar → Shark) with XP rewards
- **Activity Tracking**: GitHub-style commitment charts showing daily activity

### Estimated Timeline
Total development time: **16-22 weeks** across 9 phases

See `/roadmap/ROADMAP.md` for detailed task breakdowns, technical specifications, and implementation guidelines for each feature.

## Current Implementation Status

### ✅ Completed Features
- User authentication and registration
- Goal CRUD operations with ownership controls
- Goal steps management (up to 20 per goal)
- Social features (likes, subscriptions) with self-interaction restrictions
- Post creation and management with like functionality
- Goal image file upload (drag & drop, replaces URL-based editing)
- Privacy settings (public/private/friends)
- Responsive mobile-first design with Soft Modern design system
- Comprehensive test coverage
- Challenge system (templates, personal challenges, phases, steps, tasks, daily check-ins)
- Challenge categories (admin CRUD)
- Business rules (role-aware active item limits: admin=unlimited, pro=10, free=3)
- Social connections (following, followers, friends, friend requests)
- User following and friendship system
- Avatar file upload
- Activity feed with commitment charts
- XP/level gamification system

### 🚧 In Development
- REST API for all user-facing features
- Following the roadmap phases for systematic feature rollout

This documentation serves as the complete guide for developing and maintaining the HeadsUp social goal tracking platform.