# TC-125: Delete Step

## Linked User Story
- [US-105](../USER-STORY/US-105-goal-steps.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User owns the goal
- Step exists

## Test Steps
1. Navigate to owned goal detail
2. Click delete icon on step
3. Confirm deletion

## Expected Results
- Step is removed
- Progress is recalculated
- Other steps maintain order

## Test Data
| Field | Value |
|-------|-------|
| step_to_delete | Step 2 |

## Edge Cases
- Delete completed step
- Delete all steps

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
