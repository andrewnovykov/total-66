References
- TRD: project_doc/docs/requirements/04-features/04-goals.md
- TRD: project_doc/docs/specifications/data-model.md
- TRD IDs: REQ-04, SPEC-DATA

Status
- State: DONE
- Completed Date: 2026-02-07

Next Step
- Next PRD: project/sprint-1/PRD-3.md

---

### 1.2 Goal Status Management
- [x] Add `status` field to goals table (active, frozen, completed, failed, deleted)
- [x] Implement goal freezing functionality
  - [x] Add "Freeze Goal" button for goal owners
  - [x] Disable editing/posting when goal is frozen
  - [x] Add "Unfreeze Goal" button with confirmation
- [x] Create goal deletion functionality
  - [x] Soft delete goals (mark as deleted, don't remove from DB)
  - [x] Only goal owners can delete their goals
  - [x] Add confirmation dialog for deletion

#### Implementation Details

**Status Field** (`lib/heads_up/goals/goal.ex:9`):
- Ecto.Enum with values: `[:active, :frozen, :completed, :failed, :deleted]`

**Freeze/Unfreeze** (`lib/heads_up/goals.ex`):
- `freeze_goal/1` — sets status to `:frozen`
- `unfreeze_goal/1` — sets status to `:active`
- `freeze_goal_with_ownership/2` — ownership check + rejects failed goals
- `unfreeze_goal_with_ownership/2` — ownership check

**LiveView Guards** (`lib/heads_up_web/live/goal_live/show.ex`):
- Freeze/Unfreeze buttons with `data-confirm` dialogs
- Editing/posting disabled when frozen: `@goal.status not in [:frozen, :failed, :deleted]`
- Buttons hidden for failed/completed/deleted goals

**Soft Delete** (`lib/heads_up/goals.ex`):
- `soft_delete_goal/1` — sets `status: :deleted, deleted_at: now()`
- `soft_delete_goal_with_ownership/2` — ownership check
- `restore_goal/1` — clears `deleted_at`, sets status back to `:active`
- Queries filter `is_nil(g.deleted_at)` by default

**Tests:**
- `test/heads_up/goal_freeze_test.exs` — 9 freeze/unfreeze tests
- `test/heads_up/goal_deletion_test.exs` — 14 soft delete/restore tests
- `test/heads_up_web/live/bug2_failed_goal_restrictions_test.exs` — 10 BUG-2 regression tests
