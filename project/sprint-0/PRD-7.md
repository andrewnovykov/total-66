References

- TRD: project_doc/docs/requirements/04-features/07-people-directory-profiles.md
- TRD: project_doc/docs/requirements/04-features/08-social-graph.md
- TRD: project_doc/docs/design/pages/07-people.md
- TRD: project_doc/docs/design/pages/08-profile.md
- TRD: project_doc/docs/specifications/data-model.md
- TRD IDs: REQ-07, REQ-08, DESIGN-07, DESIGN-08, SPEC-DATA

Status

- State: DONE
- Completed Date: 2026-02-07

Next Step

- Next PRD: project/sprint-0/PRD-8.md

---

### 0.7 People & Social Graph

- [x] People directory + profiles
- [x] Follow users (one-way)
- [x] Friend requests (mutual)
- [x] Friends-only visibility enforcement

Related PRDs (all DONE):
- project/sprint-1/PRD-4.md — Connections Manager Page
- project/sprint-4/PRD-1.md — User Following
- project/sprint-4/PRD-3.md — Privacy & Friends System
- project/sprint-4/PRD-4.md — Social Feed

#### Implementation Details

**People Directory** (`lib/heads_up_web/live/users_live/index.ex`):
- Route: `/people` (public, no auth required)
- Search by name, username, bio
- User cards with privacy indicators (lock icon for private)
- Stats: goal count, challenge count, level
- Links to `/people/:username` profiles

**User Profiles** (`lib/heads_up_web/live/users_live/show.ex`):
- Route: `/people/:username` (public)
- Bio, about section, avatar (editable by owner)
- Privacy toggle: public/friends_only/private
- Follow/unfollow, friend request buttons
- Follower/following/friends counts
- User's public goals and challenges
- Commitment chart (privacy-aware)
- Level and XP progress

**Follow System** (`lib/heads_up/user_follow.ex` + `lib/heads_up/accounts.ex`):
- `user_follows` table with unique composite index
- Privacy-aware: rejects follows on private/friends_only users
- Activity tracking for both follower and followee
- API: POST/DELETE `/api/users/:id/follow`

**Friendship System** (`lib/heads_up/friendship.ex` + `lib/heads_up/accounts.ex`):
- `friendships` table with status: pending/accepted/declined/blocked
- Full workflow: send/accept/decline/cancel/remove
- API: POST/DELETE friend request endpoints

**Connections Page** (`lib/heads_up_web/live/connections_live/index.ex`):
- Route: `/connections` (authenticated)
- Tabs: Following, Followers, Friends, Requests (incoming + sent)
- Stats summary bar with counts

**Feed Page** (`lib/heads_up_web/live/feed_live/index.ex`):
- Route: `/feed` (authenticated)
- Activities from followed users + friends
- Activity types: goal_created/completed/failed, post_created, user_followed, friend_request_accepted
- Offset-based pagination with Load More
- PubSub real-time updates

**Privacy Enforcement:**
- Profile visibility: public/private/friends_only
- Follow restrictions based on user privacy
- Goal subscription privacy checks
- Content filtering for non-friends

**Tests:**
- `test/heads_up_web/live/users_live_index_test.exs` — 7 tests (directory)
- `test/heads_up_web/live/users_live_show_social_test.exs` — 30 tests (profiles + social)
- `test/heads_up_web/live/connections_live_test.exs` — 9 tests (connections)
- `test/heads_up_web/live/feed_live_test.exs` — 4 tests (feed)
- `test/heads_up_web/controllers/api/user_api_test.exs` — 23 tests (API)
- `test/heads_up_web/live/commitment_chart_privacy_test.exs` — 18 tests (privacy)
- `test/heads_up_web/live/goal_privacy_test.exs` — 16 tests (goal privacy)
- `test/heads_up/goal_subscription_test.exs` — 5 tests (subscriptions)
