# Phase 4: Social Following System

### 4.1 User Following
- [ ] Create `user_follows` table (follower_id, following_id, created_at)
- [ ] Add "Follow User" functionality
- [ ] Add "Unfollow User" functionality
- [ ] Display follower/following counts on profiles
- [ ] Create followers/following lists pages

### 4.2 Group Following
- [ ] Create `group_follows` table (user_id, group_id, created_at)
- [ ] Add "Follow Group" functionality
- [ ] Track group followers
- [ ] Group activity notifications

### 4.3 Privacy & Friends System
- [ ] Add `profile_visibility` field to users (public, private, friends_only)
- [ ] Create `friend_requests` table
- [ ] Implement friend request system:
  - [ ] Send friend request
  - [ ] Accept/decline requests
  - [ ] Remove friends
- [ ] Privacy-based content filtering

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
