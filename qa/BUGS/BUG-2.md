# BUG-2: Failed Goals Allow Freeze and Edit Actions

## Status
- [x] Investigating
- [x] Documented
- [x] In Progress
- [x] Fixed
- [x] Verified

## Resolution
- **Fixed Date:** 2026-02-07
- **Tests Added:** 10 new regression tests
- **Files Modified:**
  - `lib/heads_up_web/live/goal_live/show.ex` — Wrapped freeze/edit buttons in status guard
  - `lib/heads_up_web/live/goal_live/edit.ex` — Added failed/deleted status check in mount
  - `lib/heads_up_web/live/my_goals_live/index.ex` — Hidden edit link for failed goals

## References
- User Story: [US-103](../USER-STORY/US-103-goal-status-management.md)
- Test Case: [TC-117](../Test-Case/TC-117-goal-freeze-failed-blocked.md)
- Test Case: [TC-118](../Test-Case/TC-118-goal-edit-failed-blocked.md)

## Priority
High

---

## Summary
Users should not be able to freeze or edit failed goals. Currently the UI shows freeze and edit buttons for failed goals.

## Steps to Reproduce

### Issue 1: Freeze on failed goal
1. User has a goal with status "failed"
2. Navigate to /goals/:id (goal show page)
3. In Goal Management section, "Freeze Goal" button is visible
4. Backend rejects the action, but UI should not show the button

### Issue 2: Edit on failed goal
1. User has a goal with status "failed"
2. Navigate to /goals/:id (goal show page)
3. "Edit Goal Details" button is visible and clickable
4. Navigate to /goals/:id/edit — form loads and can be submitted
5. Also visible on /my-goals page as "Edit" link on failed goal cards

## Expected Result
- Freeze/Unfreeze buttons hidden for failed goals (on show page and my-goals)
- Edit button hidden for failed goals (on show page and my-goals)
- Direct navigation to /goals/:id/edit for a failed goal redirects to /my-goals with error

## Actual Result
- Freeze button visible on show page for failed goals (backend rejects but poor UX)
- Edit button visible on show page for all statuses including failed
- Edit page loads for failed goals with no guard
- Edit link visible on my-goals cards for failed goals

---

## Investigation

### Related Files
- `lib/heads_up/goals.ex` — `freeze_goal_with_ownership/2` already blocks failed (line 188)
- `lib/heads_up_web/live/goal_live/show.ex` — Goal Management buttons (lines 1509-1537)
- `lib/heads_up_web/live/goal_live/edit.ex` — mount guard (lines 6-41)
- `lib/heads_up_web/live/my_goals_live/index.ex` — goal card actions (lines 363-411)
- `lib/heads_up_web/controllers/api/goal_controller.ex` — API already handles :failed error

### Root Cause Analysis
1. **Freeze button on show page**: The template uses `if @goal.status == :frozen` to show Unfreeze, else shows Freeze. Missing check to exclude failed/completed/deleted statuses.
2. **Edit button everywhere**: No status check at all. Edit is always shown for owners.
3. **Edit page mount**: Only checks ownership, not goal status. Should redirect failed/deleted goals.

### Proposed Fix
1. Show page: Wrap freeze/edit buttons with `@goal.status not in [:failed, :completed, :deleted]`
2. My-goals page: Same guard on Edit link and freeze button
3. Edit page mount: Add status check — redirect failed/deleted goals with error flash
