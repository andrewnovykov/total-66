# BUG-3: Post Edit/Delete Allowed on Failed Goals

## Status
- [x] Investigating
- [x] Documented
- [x] In Progress
- [x] Fixed
- [x] Verified

## Resolution
- **Fixed Date:** 2026-02-07
- **Tests Added:** 6 new regression tests
- **Files Modified:**
  - `lib/heads_up_web/live/goal_live/show.ex` — Added goal status guard to post edit/delete buttons and event handlers

## References
- User Story: [US-103](../USER-STORY/US-103-goal-status-management.md)
- Test Case: [TC-119](../Test-Case/TC-119-post-edit-failed-goal-blocked.md)

## Priority
High

---

## Summary
Users should not be able to edit or delete posts on failed goals. Currently the edit/delete buttons are visible and functional for posts on failed goals.

## Steps to Reproduce
1. User has a goal with posts, then marks it as failed
2. Navigate to /goals/:id (failed goal show page)
3. Post edit (pencil) and delete (trash) buttons are visible on own posts
4. Clicking edit opens the edit form and allows saving changes
5. Clicking delete removes the post

## Expected Result
- Post edit/delete buttons hidden for failed goals
- Event handlers reject edit/delete actions for posts on failed goals

## Actual Result
- Edit/delete buttons visible on posts for failed goals
- Edit/delete actions succeed on posts for failed goals

---

## Investigation

### Related Files
- `lib/heads_up_web/live/goal_live/show.ex` — Post action buttons (line 1625-1633), edit_post handler (line 746), update_post handler (line 773), delete_post handler (line 709)

### Root Cause Analysis
1. **Post action buttons** (line 1625): Only check `@current_user_id == post.user_id` — no goal status check
2. **Event handlers**: `edit_post`, `update_post`, `delete_post` only validate ownership, not goal status
3. **Create post form** (line 1562): Already correctly guarded with `@goal.status not in [:frozen, :failed, :deleted]`

### Proposed Fix
1. Template: Add `@goal.status not in [:failed, :deleted]` guard around edit/delete buttons
2. Event handlers: Add goal status check to reject actions on failed/deleted goals
