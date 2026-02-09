# TC-118: Edit Blocked for Failed Goal

## Linked User Story
- [US-103](../USER-STORY/US-103-goal-status-management.md)

## Test Type
E2E / LiveView

## Priority
Critical (regression test for BUG-2)

## Preconditions
- User is logged in
- User owns the goal
- Goal status is "failed"

## Test Steps
1. Navigate to owned failed goal detail page
2. Observe Goal Management section — Edit button should NOT be visible
3. Try navigating directly to /goals/:id/edit
4. Observe redirect back with error message

## Expected Results
- Edit button is hidden for failed goals on show page
- Edit link is hidden for failed goals on my-goals page
- Direct navigation to /goals/:id/edit redirects to /my-goals with error
- Error message: "Failed goals cannot be edited"

## Test Data
| Field | Value |
|-------|-------|
| goal_status | failed |

## Edge Cases
- Goal was recently failed (just seconds ago)
- Goal has existing editable fields

## Bug Reference
- BUGS/BUG-2.md

## Automation Status
- [x] Automated in: `test/heads_up_web/live/bug2_failed_goal_restrictions_test.exs`
