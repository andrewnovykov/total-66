# Project Brief — HeadsUp (GoalHub working name)

> Quick reference for AI agents. For full details, follow the links below.

## One-Line Description

A goal-first social network that helps goal creators, accountability partners, and coaches to set structured goals and challenges, track progress, and stay accountable socially.

## Tech Stack (one-liner per layer)

- **Runtime:** Elixir ~> 1.14 + Erlang/OTP
- **Framework:** Phoenix 1.7.21 (LiveView ~> 1.0.10)
- **Database:** PostgreSQL via Ecto 3.12.5
- **Styling:** Tailwind CSS 3.4.3 + Heroicons v2.1.1
- **Auth:** Session tokens with Bcrypt — see `/project_doc/specifications/auth-strategy.md`
- **Testing:** ExUnit + Floki — see `/project_doc/specifications/testing-strategy.md`
- **Deploy:** Docker-ready with Bandit HTTP server — see `/project_doc/specifications/deployment-infra.md`

> Full details: `/project_doc/specifications/tech-stack.md`

## Architecture Pattern

Phoenix contexts for bounded domain logic (`Goals`, `Accounts`, `Auth`, `Groups`, `Challenges`), service modules for cross-cutting concerns (`ActivityService`, `FeedService`), LiveView for real-time UI with `on_mount` hooks for authentication. Ownership-based authorization pattern throughout. See `/project_doc/specifications/folder-structure.md`.

## Users

**User Type 1: Guest (Visitor)**

- Can do: Browse public content (Home, Goals, Challenges, Groups, People), open public goal/challenge/profile pages
- Can see: Trending goals, popular groups, spotlight users, public profiles, public goals and goal posts
- Can create/edit/delete: Nothing

**User Type 2: Regular User (Goal Creator)**

- Can do: Create/manage goals and challenges, join predefined challenges, join group goals, follow/unfollow users and goals, send/accept friend requests, like/dislike/comment on goals and posts, create goal posts
- Can see: Public content + friends-only content from accepted friends + own private content + commitment charts
- Can create/edit/delete: Own goals (with phases/steps), own custom challenges (tasks + schedules), own posts/comments, manage subscriptions/follows/friends

**User Type 3: Coach**

- Can do: Everything a regular user can + create group goal templates, add participants, start group goals, monitor participant progress in dashboards
- Can see: Coach Center + group goal dashboards + participant progress/activity for group goals they manage
- Can create/edit/delete: Group goal templates (before start), manage enrollments/participants, archive group goals

**User Type 4: Admin**

- Can do: Create/edit/delete goal categories; create/edit/disable predefined challenge templates (phases/steps)
- Can see: Admin panel pages (categories, predefined challenges)
- Can create/edit/delete: Categories, predefined challenges (templates)

## MVP Features

### Feature 1: Goals (Structured Goals with Phases & Steps)

As a regular user, I want to create a goal with phases and steps, so that I can execute a structured plan and track real progress.

**Details:**

- Goal has: title, optional description, optional image, category (admin-defined), visibility (public/friends/private), status (active/frozen/completed/failed), optional due date
- Goal structure: phases → steps (steps can be completed, progress bar updates)
- Goal detail includes: phases/steps + goal feed (posts), likes/dislikes, comments, subscribe (follow goal)

### Feature 2: Challenges (Predefined + Custom with Scheduling)

As a regular user, I want to join an admin challenge or create my own challenge with scheduled tasks, so that I can follow structured programs or build habit routines.

**Details:**

- Menu item: Challenges
- Predefined challenges (admin-created): phases/steps (read-only template), users join and complete
- Custom challenges (user-created): tasks with schedule options (daily, twice/week, every other day, Mon–Fri, custom weekdays)
- Challenges count toward the "3 active items" rule when active

### Feature 3: Coach Center (Group Goals + Dashboard)

As a coach, I want to create a group goal template and enroll people, so that each participant gets their own goal instance and I can track their progress.

**Details:**

- Coach creates Group Goal Template (phases/steps)
- Coach adds participants and starts the group goal
- System generates an individual goal instance for each participant from template
- Coach dashboard shows: participant list, status, progress, last activity, commitment heatmap, at-risk users
- Coach cannot edit participant progress; participants report by completing steps and posting updates

> Full specs: `/project_doc/requirements/03-features-mvp.md`

## Key Constraints

- **Performance**: LiveView real-time updates via Phoenix PubSub, database query optimization with proper indexing
- **Security**: Bcrypt password hashing, CSRF protection, ownership validation on all mutations, self-interaction prevention (can't like own content)
- **Accessibility**: Mobile-first responsive design with Tailwind CSS
- **Browser support**: Modern browsers (last 2 versions of Chrome, Firefox, Safari, Edge)

> Full requirements: `/project_doc/specifications/nfr.md`

## Data Entities

1. **User**: id, email, password_hash, username/nickname, display_name, bio, avatar_url, level, role (user/coach/admin), activity_history, followers, following, friends,
2. **Goal**: id, owner_user_id, title, description, image_url, category_id, visibility, status, due_date, phases, steps, posts, subscribers, likes, progress
3. **Challenge**: id, type (predefined/custom), creator_user_id, category_id, title, description, phases/steps (predefined) OR tasks+schedules (custom), participants/enrollments
4. **GroupGoalTemplate**: coach-created goal template for group enrollment
5. **GroupGoalEnrollment**: participant enrollment in group goals
6. **FollowUser**: user follow relationships
7. **FriendRequest**: friend request with accept/decline workflow
8. **GoalSubscription**: goal subscription tracking
9. **Reaction**: likes/dislikes on goals and posts
10. **Comment**: comments on goal posts
11. **GoalPost**: post_type (update/milestone/achievement/challenge/motivation), content, image

<!-- TODO: FILL IN! -->

> Full schema: `/project_doc/specifications/data-model.md`

## Pages

1. **Home**: for everyone, shows trending goals + popular groups + spotlight users, can open details (and logged-in can follow/like/comment where allowed)
2. **Goals**: for everyone, shows searchable goal feed with goal cards, can open goal detail, follow goal, like/dislike/comment (visibility rules apply)
3. **Goal Detail**: for permitted viewers, shows goal header + phases/steps + progress + goal posts feed, can post updates (owner), react/comment (allowed users)
4. **Challenges**: for everyone, shows predefined and community challenges, can join (logged-in) or create custom challenges (logged-in)
5. **People**: for everyone, shows search + top goal setters + recommendations (logged-in), can follow/add friend
6. **Profile**: for everyone, shows user info + counts + commitment chart + goals list (visibility-gated), can follow/add friend
7. **My Goals**: for logged-in users, shows personal goals/challenges/group instances, can create/edit/delete, change status, see active count/3
8. **Coach Center**: for coaches only, shows group goal templates, participant management, start flows, dashboards
9. **Admin Panel**: for admins only, manage categories + predefined challenges (templates)

> Full user flows: `/project_doc/specifications/user-flows.md`

## Integrations

- [ ] **Payments**: Not needed in MVP
- [ ] **Email**: Optional in MVP; recommended for verification/password reset/notifications
- [ ] **Maps**: Not needed
- [ ] **File Storage**: For images (avatars, goal images, post media)

> Full integration details: `/project_doc/specifications/integrations-technical.md`

## Detailed Specification Docs

| Doc                      | Path                                                    |
| ------------------------ | ------------------------------------------------------- |
| Tech Stack               | `/project_doc/specifications/tech-stack.md`             |
| Folder Structure         | `/project_doc/specifications/folder-structure.md`       |
| Data Model               | `/project_doc/specifications/data-model.md`             |
| API Design               | `/project_doc/specifications/api-design.md`             |
| Auth Strategy            | `/project_doc/specifications/auth-strategy.md`          |
| Environment Config       | `/project_doc/specifications/environment-config.md`     |
| Testing Strategy         | `/project_doc/specifications/testing-strategy.md`       |
| Deployment & Infra       | `/project_doc/specifications/deployment-infra.md`       |
| Non-Functional Reqs      | `/project_doc/specifications/nfr.md`                    |
| Code Style               | `/project_doc/specifications/code-style.md`             |
| Integrations (Technical) | `/project_doc/specifications/integrations-technical.md` |
| User Flows               | `/project_doc/specifications/user-flows.md`             |

## Device Support

- [x] Desktop
- [x] Mobile
- [x] Both

## Business Rules

- Max 3 active items per user at the same time (active goals + active challenges + active coach-assigned group goal instances)
- Visibility per goal/challenge: public / friends-only / private (friends-only requires accepted friendship; private is owner-only; coach can still view participant progress for their group goals)
- Predefined challenges are template-locked: participants cannot edit phases/steps
- Reactions are exclusive: a user can either like or dislike a target (toggle behavior), not both
- Frozen goals cannot be edited until unfrozen
- Failed goals require a failure reason

## Visual Style

- **Style**: Modern
- **Colors**: Primary: Brand Indigo (`#6366f1`), Secondary: Teal (`#14b8a6`)
- **Fonts**: Be Vietnam Pro (Primary), Noto Sans (Secondary)
- **Reference**: Strava, Airbnb, Linear
- **Framework**: Tailwind CSS 3.4.3
- **Icons**: Heroicons v2.1.1
