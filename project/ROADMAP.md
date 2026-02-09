# HeadsUp Platform Roadmap

## Project Overview
A comprehensive goal-setting and achievement platform with social features, gamification, and admin management capabilities.

---

## Phase 0: Core MVP Foundations
**Priority: Highest** | **Timeline: 3-5 weeks**

### 0.1 Authentication & Roles
- [ ] Registration (email + password + username)
- [ ] Login / Logout
- [ ] Role system: user / coach / admin
- [ ] Role-based navigation and route guards

### 0.2 Goals (Create + Detail + Feed)
- [ ] Goal creation with phases and steps
- [ ] Goal visibility: public / friends-only / private
- [ ] Goal detail page with progress and posts feed
- [ ] Goal reactions (like/dislike) and comments
- [ ] Goal subscriptions (follow goal)

### 0.3 Challenges (Predefined + Custom)
- [ ] Admin predefined challenge templates (phases/steps)
- [ ] User join predefined challenges
- [ ] User-created challenges with task schedules
- [ ] Challenge visibility rules + progress tracking

### 0.4 My Goals Dashboard
- [ ] Unified dashboard for goals, challenges, group goal instances
- [ ] Status transitions (active / frozen / completed / failed)
- [ ] Edit/delete own items (with restrictions)

### 0.5 Coach Center & Group Goals
- [ ] Coach creates group goal templates
- [ ] Enroll participants and start group goals
- [ ] Coach dashboard with progress, activity, at-risk indicators

### 0.6 Categories (Admin-managed)
- [ ] Admin CRUD for goal/challenge categories
- [ ] Category usage in creation and filtering
- [ ] Deletion rules (reassign or block if in use)

### 0.7 People & Social Graph ✅
- [x] People directory + profiles
- [x] Follow users (one-way)
- [x] Friend requests (mutual)
- [x] Friends-only visibility enforcement
- [x] Connections Manager page (/connections)

### 0.8 Discovery Pages
- [ ] Home: trending goals, popular groups, spotlight users
- [ ] Goals directory with search/filter/sort
- [ ] Challenges directory with tabs and filters
- [ ] Groups directory

### 0.9 Global Business Rules
- [ ] Enforce max 3 active items rule
- [ ] Like/dislike toggle per target
- [ ] Guest interaction restrictions

---

## Phase 1: Security & Ownership Controls
**Priority: High** | **Timeline: 2-3 weeks**

### 1.1 Goal & Post Ownership
- [ ] Implement goal ownership validation
  - [ ] Only goal owners can edit goal details
  - [ ] Only goal owners can add/edit goal steps
  - [ ] Only goal owners can create posts in their goals
- [ ] Implement post ownership validation
  - [ ] Only post authors can edit their posts
  - [ ] Only post authors can delete their posts
  - [ ] Users can delete their own posts from any goal
- [ ] Add server-side validation for all ownership checks
- [ ] Create comprehensive tests for ownership controls

### 1.2 Goal Status Management
- [ ] Add `status` field to goals table (active, frozen, completed, failed, deleted)
- [ ] Implement goal freezing functionality
  - [ ] Add "Freeze Goal" button for goal owners
  - [ ] Disable editing/posting when goal is frozen
  - [ ] Add "Unfreeze Goal" button with confirmation
- [ ] Create goal deletion functionality
  - [ ] Soft delete goals (mark as deleted, don't remove from DB)
  - [ ] Only goal owners can delete their goals
  - [ ] Add confirmation dialog for deletion

### 1.3 Goal Failure System
- [ ] Add goal failure functionality
  - [ ] "Fail Goal" button for goal owners
  - [ ] Required failure reason/conclusion field
  - [ ] Store failure data with timestamp
- [ ] Update goal status to "failed"
- [ ] Display failure reasons in goal history

---

## Phase 2: Spam Reporting & Moderation
**Priority: High** | **Timeline: 2 weeks**

### 2.1 Spam Reporting System
- [ ] Create `reports` table (goal_id, post_id, user_id, reason, created_at)
- [ ] Add red flag icon to every goal
- [ ] Add red flag icon to every post
- [ ] Implement reporting functionality
  - [ ] Report modal with reason selection
  - [ ] Prevent duplicate reports from same user
  - [ ] Track report counts per goal/post

### 2.2 Bug Reporting System
- [ ] Create `bug_reports` table (user_id, page_name, description, status, created_at)
- [ ] Add bug report icon to all pages
- [ ] Implement bug reporting functionality
  - [ ] Bug report modal with page name selection
  - [ ] Description field for bug details
  - [ ] Track bug report status (open, in_progress, resolved)
- [ ] Admin dashboard integration for bug reports
  - [ ] List all bug reports
  - [ ] Filter by status and page
  - [ ] Mark bugs as resolved

### 2.3 Auto-Moderation
- [ ] Create moderation logic
  - [ ] Auto-hide goals with 3+ spam reports
  - [ ] Auto-hide posts with 3+ spam reports
  - [ ] Send to admin queue for review
- [ ] Add `moderation_status` field (clean, flagged, hidden, reviewed)
- [ ] Implement content filtering for hidden items

---

## Phase 3: Admin Dashboard
**Priority: High** | **Timeline: 2-3 weeks**

### 3.1 Admin Authentication & Access Control
- [ ] Create admin role system
- [ ] Add `is_admin` field to users table
- [ ] Implement admin-only routes and middleware
- [ ] Create admin login/authentication

### 3.2 Admin Analytics Dashboard
- [ ] Create admin dashboard layout
- [ ] Display key metrics:
  - [ ] Total users count
  - [ ] Total posts count
  - [ ] Total goals count
  - [ ] Total groups count
  - [ ] Active users (last 30 days)
  - [ ] New signups (daily/weekly/monthly)
- [ ] Add charts and visualizations
- [ ] Real-time updates for metrics

### 3.3 Group & Category Management
- [ ] Admin can create new groups/categories
- [ ] Admin can create subgroups
  - [ ] Example: "Learn Language" → "Learn Spanish"
- [ ] Hierarchical group structure
- [ ] Admin can edit/delete groups
- [ ] Group ordering and organization

### 3.4 Content Moderation Panel
- [ ] List all flagged goals awaiting moderation
- [ ] List all flagged posts awaiting moderation
- [ ] List all flagged users
- [ ] Moderation actions:
  - [ ] Approve content (remove from moderation)
  - [ ] Keep hidden (confirm spam)
  - [ ] Delete content permanently
  - [ ] Block users
- [ ] Moderation history and audit trail

### 3.5 Bug Reports Management
- [ ] Bug reports dashboard section
- [ ] List all bug reports with filters
- [ ] Bug report details view
- [ ] Status management (open, in_progress, resolved)
- [ ] Priority assignment for bug reports
- [ ] Admin notes/comments on bug reports

### 3.6 User Management
- [ ] User listing with search and filters
- [ ] User profiles and activity overview
- [ ] Block/unblock users functionality
- [ ] User activity monitoring
- [ ] Send warnings/messages to users

---

## Phase 4: Social Following System
**Priority: Medium** | **Timeline: 2-3 weeks**

### 4.1 User Following ✅ (Completed Sprint 1)
- [x] Create `user_follows` table (follower_id, following_id, created_at)
- [x] Add "Follow User" functionality
- [x] Add "Unfollow User" functionality
- [x] Display follower/following counts on profiles
- [x] Create followers/following lists pages

### 4.2 Group Following
- [ ] Create `group_follows` table (user_id, group_id, created_at)
- [ ] Add "Follow Group" functionality
- [ ] Track group followers
- [ ] Group activity notifications

### 4.3 Privacy & Friends System ✅ (Completed Sprint 1)
- [x] Add `profile_visibility` field to users (public, private, friends_only)
- [x] Create `friendships` table
- [x] Implement friend request system:
  - [x] Send friend request
  - [x] Accept/decline requests
  - [x] Cancel sent requests
  - [x] Remove friends
- [x] Privacy-based content filtering

### 4.4 Connections Manager Page ✅ (Completed Sprint 1)
- [x] Create `/connections` route
- [x] Tabbed interface (Following, Followers, Friends, Requests)
- [x] Stats summary bar with counts
- [x] Following tab with unfollow action
- [x] Followers tab with remove follower action
- [x] Friends tab with remove friend action
- [x] Requests tab with incoming/sent sections

### 4.4 Social Feed
- [ ] Create main feed page
- [ ] Display updates from followed users:
  - [ ] New goals created
  - [ ] Goals completed
  - [ ] Major milestones reached
- [ ] Display updates from followed groups:
  - [ ] "In group [X] new goal '[Title]' was created"
  - [ ] Popular goals in followed groups
- [ ] Feed filtering and sorting options
- [ ] Pagination and infinite scroll

---

## Phase 5: Online Status & Real-time Features
**Priority: Low** | **Timeline: 1 week**

### 5.1 Online Status System
- [ ] Track user online status
- [ ] Add `last_seen_at` field to users
- [ ] Implement online status indicators:
  - [ ] Green dot = online (active in last 5 minutes)
  - [ ] Red dot = offline
- [ ] Display status near user avatars
- [ ] Real-time status updates using Phoenix channels

### 5.2 Real-time Notifications
- [ ] Implement Phoenix channels for real-time updates
- [ ] Live notifications for:
  - [ ] New followers
  - [ ] Friend requests
  - [ ] Goal likes/comments
- [ ] Browser notifications (optional)

---

## Phase 6: Challenges System
**Priority: Medium** | **Timeline: 3-4 weeks**

### 6.1 Challenge Infrastructure
- [ ] Create `challenges` table (title, description, duration, group_id, created_by)
- [ ] Create `challenge_tasks` table (challenge_id, title, description, day_number)
- [ ] Create challenge groups and subgroups:
  - [ ] 30-day challenges
  - [ ] 90-day challenges
  - [ ] Custom duration challenges
- [ ] Admin can create challenge templates

### 6.2 Task Recurrence System
- [ ] Add `recurrence_type` to challenge tasks (daily, semi_daily, weekly, monthly, custom)
- [ ] Add `recurrence_pattern` for custom schedules
- [ ] Task scheduling logic
- [ ] Support for specific days selection

### 6.3 User Challenge Participation
- [ ] Create `user_challenges` table (user_id, challenge_id, status, started_at)
- [ ] Create `user_challenge_progress` table (user_challenge_id, task_id, completed_at)
- [ ] "Use as Template" functionality
- [ ] One active challenge per user restriction
- [ ] Daily task completion tracking
- [ ] Challenge progress visualization

### 6.4 My Challenges Section
- [ ] Add "My Challenges" section to user dashboard
- [ ] Display current active challenge
- [ ] Show challenge history (completed/failed)
- [ ] Challenge statistics and progress charts

---

## Phase 7: Gamification & Level System
**Priority: Medium** | **Timeline: 2-3 weeks**

### 7.1 Experience Points (XP) System
- [ ] Add `xp` and `level` fields to users table
- [ ] Define XP rewards:
  - [ ] Like given/received: 1 XP
  - [ ] Post created: 10 XP
  - [ ] Goal completed: 1000 XP
  - [ ] Challenge completed: 500 XP
  - [ ] Daily task completed: 5 XP
- [ ] Implement XP tracking and calculation

### 7.2 Level System with Ocean Theme
- [ ] Create level progression system:
  - [ ] Level 1-5: Seastar (0-100 XP)
  - [ ] Level 6-10: Hermit Crab (101-300 XP)
  - [ ] Level 11-15: Jellyfish (301-600 XP)
  - [ ] Level 16-20: Sea Turtle (601-1000 XP)
  - [ ] Level 21-25: Dolphin (1001-1500 XP)
  - [ ] Level 26-30: Octopus (1501-2100 XP)
  - [ ] Level 31-35: Whale (2101-2800 XP)
  - [ ] Level 36-40: Shark (2801+ XP)
- [ ] Level badges and icons
- [ ] Level progression animations

### 7.3 Level Penalties
- [ ] Implement level drop system:
  - [ ] Goal failure: -1 level
  - [ ] Challenge failure: -1 level
  - [ ] Minimum level: 1 (Seastar)
- [ ] Track level history
- [ ] Recovery paths and motivation

---

## Phase 8: Activity Tracking & Analytics
**Priority: Low** | **Timeline: 2 weeks**

### 8.1 Activity Tracking System
- [ ] Create `user_activities` table (user_id, activity_type, points, created_at)
- [ ] Track all user actions:
  - [ ] Goals created/completed/failed
  - [ ] Posts created
  - [ ] Likes given
  - [ ] Challenges started/completed
  - [ ] Daily logins

### 8.2 Commitment Chart
- [ ] Create GitHub-style activity heatmap
- [ ] Show daily activity levels
- [ ] Color coding based on activity intensity
- [ ] Monthly/yearly views
- [ ] Activity streaks tracking

### 8.3 Personal Analytics
- [ ] User progress dashboards
- [ ] Goal completion rates
- [ ] Challenge success rates
- [ ] Activity trends and insights
- [ ] Personal achievement timeline

---

## Phase 9: Mobile & Performance Optimization
**Priority: Low** | **Timeline: 2 weeks**

### 9.1 Mobile Responsiveness
- [ ] Optimize all interfaces for mobile
- [ ] Touch-friendly interactions
- [ ] Mobile navigation improvements
- [ ] PWA capabilities

### 9.2 Performance Optimization
- [ ] Database query optimization
- [ ] Image optimization and CDN
- [ ] Caching strategies
- [ ] Page load speed improvements

---

## Technical Considerations

### Database Design
- Ensure proper indexing for performance
- Implement soft deletes where appropriate
- Use proper foreign key constraints
- Consider data archival strategies

### Security
- Input validation and sanitization
- Rate limiting for actions
- CSRF protection
- SQL injection prevention

### Scalability
- Database connection pooling
- Background job processing
- Caching layer implementation
- Load balancing considerations

### Testing Strategy
- Unit tests for all business logic
- Integration tests for user flows
- Performance testing
- Security testing

---

## Deployment & DevOps

### Staging Environment
- [ ] Set up staging server
- [ ] CI/CD pipeline
- [ ] Automated testing
- [ ] Database migration strategy

### Production Deployment
- [ ] Production server setup
- [ ] SSL certificate installation
- [ ] Database backup strategy
- [ ] Monitoring and logging

### Maintenance
- [ ] Regular security updates
- [ ] Performance monitoring
- [ ] User feedback collection
- [ ] Feature usage analytics

---

*Last Updated: February 2025*
*Total Estimated Timeline: 16-22 weeks*
