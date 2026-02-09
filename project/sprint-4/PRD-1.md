References
- TRD: project_doc/docs/requirements/04-features/10-follow-goals.md
- TRD: project_doc/docs/requirements/04-features/08-social-graph.md
- TRD: project_doc/docs/specifications/data-model.md
- TRD IDs: REQ-10, REQ-08, SPEC-DATA

Status
- State: DONE
- Completed Date: 2026-02-07

Next Step
- Next PRD: project/sprint-4/PRD-2.md

---

### 4.1 User Following
- [x] Create `user_follows` table (follower_id, following_id, created_at)
- [x] Add "Follow User" functionality
- [x] Add "Unfollow User" functionality
- [x] Display follower/following counts on profiles
- [x] Create followers/following lists pages

#### Implementation Details

**Schema** (`lib/heads_up/user_follow.ex`):
- `follower_id`, `following_id` with cascade deletes
- Unique composite index on `[follower_id, following_id]`
- `validate_not_self_follow/1` prevents self-follows

**Migration** (`priv/repo/migrations/20250706161620_create_user_follows.exs`)

**Context** (`lib/heads_up/accounts.ex`):
- `follow_user/2` — with privacy enforcement (rejects private/friends-only without friendship)
- `unfollow_user/2` — deletes follow record
- `is_following?/2` — boolean check
- `get_followers_count/1`, `get_following_count/1` — count aggregations
- `list_followers/1`, `list_following/1` — user lists
- `remove_follower/2` — owner removes a follower

**LiveView** (`lib/heads_up_web/live/users_live/show.ex`):
- Follow/unfollow button with real-time state updates
- Follower/following counts displayed on profiles

**Connections Page** (`lib/heads_up_web/live/connections_live/index.ex`):
- "Following" tab with unfollow action
- "Followers" tab with remove follower action

**API Endpoints:**
- `POST /api/users/:id/follow`, `DELETE /api/users/:id/follow`
- `GET /api/users/:id/followers`, `GET /api/users/:id/following`

**Tests:**
- `test/heads_up_web/live/connections_live_test.exs` — 9 tests
- `test/heads_up_web/live/users_live_show_social_test.exs` — 30 tests
- `test/heads_up_web/controllers/api/user_api_test.exs` — 23 tests
