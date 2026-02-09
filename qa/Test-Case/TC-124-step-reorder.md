# TC-124: Reorder Steps

## Linked User Story
- [US-105](../USER-STORY/US-105-goal-steps.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User owns the goal
- Goal has multiple steps

## Test Steps
1. Navigate to owned goal detail
2. Drag step from position 3 to position 1
3. Release step
4. Verify new order is saved

## Expected Results
- Step order is updated
- New order persists after refresh
- Step numbers are updated

## Test Data
| Field | Value |
|-------|-------|
| step_count | 5 |
| move_from | 3 |
| move_to | 1 |

## Edge Cases
- Move to same position
- Move last to first

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
