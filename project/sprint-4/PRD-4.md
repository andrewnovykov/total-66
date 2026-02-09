References
- TRD: project_doc/docs/requirements/04-features/18-social-feed.md
- TRD: project_doc/docs/specifications/data-model.md
- TRD: project_doc/docs/specifications/user-flow.md
- TRD IDs: REQ-18, SPEC-DATA, SPEC-FLOW

Status
- State: DONE
- Completed Date: 2026-02-07

Next Step
- Next PRD: project/sprint-5/PRD-1.md

---

### 4.4 Social Feed
- [x] Create main feed page
- [x] Display updates from followed users:
  - [x] New goals created
  - [x] Goals completed
  - [x] Major milestones reached
- [ ] Display updates from followed groups:
  - [ ] "In group [X] new goal '[Title]' was created"
  - [ ] Popular goals in followed groups
- [ ] Feed filtering and sorting options
- [x] Pagination and infinite scroll

#### Implementation Details

**Feed Page** (`lib/heads_up_web/live/feed_live/index.ex`):
- Route: `/feed` (authenticated only)
- Hero banner, activity cards, right sidebar with stats
- "Load More" button with offset-based pagination (20 items per page)
- PubSub subscription to `"user_activities"` for real-time updates
- Refresh button for manual feed reload

**Feed Service** (`lib/heads_up/feed_service.ex`):
- `get_user_feed/2` — combines following + friends + own activities
- Activity types: goal_created, goal_completed, goal_failed, post_created, user_followed, friend_request_accepted
- `get_trending_activities/1` — trending in last 7 days
- `format_activity_for_feed/1` — human-readable activity descriptions

**Activity Tracking** (`lib/heads_up/activity_service.ex`):
- 24 activity types tracked with XP rewards
- Level system with 40 ocean-themed levels

**Tests:**
- `test/heads_up_web/live/feed_live_test.exs` — 4 tests (auth, rendering, empty state, refresh)

#### Not Yet Implemented
- Group activity updates in feed (requires group following system)
- UI-level feed filtering/sorting controls
