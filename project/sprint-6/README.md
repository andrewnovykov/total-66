# Phase 6: Challenges System

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
