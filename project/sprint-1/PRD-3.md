References
- TRD: project_doc/docs/requirements/04-features/04-goals.md
- TRD: project_doc/docs/specifications/data-model.md
- TRD IDs: REQ-04, SPEC-DATA

Status
- State: DONE
- Completed Date: 2026-02-07

Next Step
- Next PRD: project/sprint-2/PRD-1.md

---

### 1.3 Goal Failure System
- [x] Add goal failure functionality
  - [x] "Fail Goal" button for goal owners
  - [x] Required failure reason/conclusion field
  - [x] Store failure data with timestamp
- [x] Update goal status to "failed"
- [x] Display failure reasons in goal history

#### Implementation Details

**Schema** (`lib/heads_up/goal.ex`):
- `failure_reason` (string) — stores the reason text
- `failed_at` (utc_datetime) — timestamp of failure
- `validate_failure_reason/1` — ensures non-empty reason when status is `:failed`

**Context** (`lib/heads_up/goals.ex`):
- `fail_goal/2` — sets status, failure_reason, failed_at
- `fail_goal_with_ownership/3` — ownership check + activity tracking + auto-creates challenge post

**LiveView** (`lib/heads_up_web/live/goal_live/show.ex`):
- "Fail Goal" button (line ~1544) opens modal
- Modal with required textarea, 500 char max, character counter
- `show_fail_modal` / `hide_fail_modal` / `fail_goal` event handlers
- Failure history display in sidebar with date and reason (lines ~1923-1934)

**Tests:**
- `test/heads_up/goal_failure_test.exs` — 12 tests (owner/non-owner, validation, timestamps)
- `test/heads_up_web/live/bug2_failed_goal_restrictions_test.exs` — 10 regression tests
- `test/heads_up_web/live/bug3_failed_goal_post_edit_test.exs` — 6 regression tests
