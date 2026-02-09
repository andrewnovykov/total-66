# TC-117: Freeze Blocked for Failed Goal

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
2. Observe Goal Management section
3. Verify freeze button is NOT visible

## Expected Results
- Freeze button is hidden for failed goals
- Only Delete button remains available
- Failed status banner is displayed

## Test Data
| Field | Value |
|-------|-------|
| goal_status | failed |

## Edge Cases
- Goal was frozen before being failed

## Bug Reference
- BUGS/BUG-2.md

## Automation Status
- [x] Automated in: `test/heads_up_web/live/bug2_failed_goal_restrictions_test.exs`
