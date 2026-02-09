# TC-119: Post Edit/Delete Blocked for Failed Goal

## Linked User Story
- [US-103](../USER-STORY/US-103-goal-status-management.md)

## Test Type
E2E / LiveView

## Priority
Critical (regression test for BUG-3)

## Preconditions
- User is logged in
- User owns a goal with status "failed"
- Goal has existing posts created by the user

## Test Steps
1. Navigate to /goals/:id (failed goal show page)
2. Observe the post action buttons area
3. Verify edit and delete buttons are NOT visible on posts
4. Verify "Share an Update" form is NOT visible

## Expected Results
- Post edit button is hidden for failed goals
- Post delete button is hidden for failed goals
- Create post form is hidden for failed goals
- Posts are still visible (read-only)

## Test Data
| Field | Value |
|-------|-------|
| goal_status | failed |

## Edge Cases
- Goal was just failed (posts existed before failure)
- Goal has posts from other users (should always be hidden for failed goal)

## Bug Reference
- BUGS/BUG-3.md

## Automation Status
- [x] Automated in: `test/heads_up_web/live/bug3_failed_goal_post_edit_test.exs`
