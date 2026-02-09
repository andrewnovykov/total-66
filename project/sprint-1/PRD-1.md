References

- TRD: project_doc/docs/requirements/04-features/04-goals.md
- TRD: project_doc/docs/specifications/api-design.md
- TRD: project_doc/docs/specifications/auth-strategy.md
- TRD IDs: REQ-04, SPEC-API, SPEC-AUTH

Status

- State: DONE
- Completed Date: 2026-02-07

Next Step

- Next PRD: project/sprint-1/PRD-2.md

---

### 1.1 Goal & Challenges / Challenge Template and Post Ownership

- [x] Implement goal ownership validation
    - [x] Only goal owners can edit goal details
    - [x] Only goal owners can add/edit goal steps
    - [x] Only goal owners can create posts in their goals
- [x] Implement post ownership validation
    - [x] Only post authors can edit their posts
    - [x] Only post authors can delete their posts
    - [x] Users can delete their own posts from any goal
- [x] Add server-side validation for all ownership checks
- [x] Create comprehensive tests for ownership controls

#### Implementation Details

**Goal Ownership** (`lib/heads_up/goals.ex`):
- `update_goal_with_ownership/3` — checks `goal.user_id == user_id`
- `create_goal_step_with_ownership/2` — checks goal owner via goal association
- `update_goal_step_with_ownership/3` — checks goal owner via step.goal
- `delete_goal_step_with_ownership/2` — checks goal owner via step.goal
- `toggle_goal_step_completion_with_ownership/2` — checks goal owner
- `freeze_goal_with_ownership/2` — checks owner + rejects failed goals
- `unfreeze_goal_with_ownership/2` — checks owner
- `soft_delete_goal_with_ownership/2` — checks owner
- `fail_goal_with_ownership/3` — checks owner

**Post Ownership** (`lib/heads_up/goals.ex`):
- `create_goal_post_with_ownership/2` — only goal owner can create posts
- `update_goal_post_with_ownership/3` — only post author can edit
- `delete_goal_post_with_ownership/2` — only post author can delete

**Challenge Ownership** (`lib/heads_up/challenges.ex`):
- `update_challenge/3` — checks `creator_user_id == user_id`
- `delete_challenge/2` — checks owner or admin role
- `share_as_template/2` — checks `creator_user_id == user_id`
- `fail_challenge/3` — checks `creator_user_id == user_id`
- Phase/Step/Task CRUD — all check challenge creator ownership
- Edit page mount — redirects non-owners

**LiveView Guards:**
- Goal show page: All events check ownership via `_with_ownership` functions
- Goal edit page: Mount checks `goal.user_id == current_user_id`, blocks failed/deleted
- Challenge show page: Delete/share/fail events use context ownership checks
- Challenge edit page: Mount redirects non-owners
- Post edit/delete buttons: Hidden for non-owners + hidden on failed goals (BUG-3)
- Create post form: Hidden for non-owners + hidden on frozen/failed/deleted goals

**Tests:**
- `test/heads_up/goal_ownership_test.exs` — 12 context-level ownership tests
- `test/heads_up/post_ownership_test.exs` — 10 context-level post ownership tests
- `test/heads_up_web/live/goal_ownership_liveview_test.exs` — 17 LiveView-level tests
- `test/heads_up_web/live/challenge_ownership_liveview_test.exs` — 10 LiveView-level tests
- `test/heads_up/challenges_test.exs` — ownership tests for update/delete
- `test/heads_up_web/live/challenge_live_test.exs` — edit page redirect test
