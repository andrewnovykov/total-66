References
- TRD: project_doc/docs/requirements/04-features/08-social-graph.md
- TRD: project_doc/docs/specifications/data-model.md
- TRD IDs: REQ-08, SPEC-DATA

Status
- State: DONE
- Completed Date: 2026-02-07

Next Step
- Next PRD: project/sprint-4/PRD-4.md

---

### 4.3 Privacy & Friends System
- [x] Add `profile_visibility` field to users (public, private, friends_only)
- [x] Create `friend_requests` table
- [x] Implement friend request system:
  - [x] Send friend request
  - [x] Accept/decline requests
  - [x] Remove friends
- [x] Privacy-based content filtering

#### Implementation Details

**Schema** (`lib/heads_up/friendship.ex`):
- `user_id`, `friend_id`, `status` (pending/accepted/declined/blocked)
- Unique composite index on `[user_id, friend_id]`
- `validate_not_self_friend/1` prevents self-friendships

**Migration** (`priv/repo/migrations/20250708185545_create_friendships.exs`):
- Indexes on user_id, friend_id, status for performance

**User Privacy** (`priv/repo/migrations/20250708185528_add_privacy_to_users.exs`):
- `privacy` field on users: public/private/friends_only (default: public)

**Context** (`lib/heads_up/accounts.ex`):
- `send_friend_request/2` — creates pending friendship
- `accept_friend_request/2` — accepts incoming request
- `decline_friend_request/2` — declines incoming request
- `cancel_friend_request/2` — sender cancels pending request
- `remove_friend/2` — removes existing friendship (both directions)
- `are_friends?/2` — checks accepted friendship
- `list_friends/1`, `list_friend_requests/1`, `list_sent_friend_requests/1`

**Privacy Enforcement:**
- Profile visibility: public/private/friends_only toggle on profile page
- Follow restrictions: cannot follow private users or friends_only without friendship
- Goal subscriptions: respects goal privacy settings
- Content filtering: private/friends_only profiles show limited info

**LiveView:**
- `users_live/show.ex`: Friend request buttons (send/cancel/accept/decline/remove)
- `connections_live/index.ex`: Friends tab + Requests tab (incoming/sent)

**Tests:**
- `test/heads_up_web/live/users_live_show_social_test.exs` — 30 tests (privacy + friends)
- `test/heads_up_web/controllers/api/user_api_test.exs` — friend request API tests
- `test/heads_up_web/live/connections_live_test.exs` — 9 tests
- `test/heads_up_web/live/commitment_chart_privacy_test.exs` — 18 privacy tests
- `test/heads_up_web/live/goal_privacy_test.exs` — 16 privacy tests
