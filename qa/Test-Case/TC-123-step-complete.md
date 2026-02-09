# TC-123: Mark Step as Completed

## Linked User Story
- [US-105](../USER-STORY/US-105-goal-steps.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User owns the goal
- Step exists and is not completed

## Test Steps
1. Navigate to owned goal detail
2. Click checkbox for incomplete step
3. Observe progress update

## Expected Results
- Step marked as completed
- Progress percentage increases
- Visual feedback (strikethrough, checkmark)

## Test Data
| Field | Value |
|-------|-------|
| step_status | completed: true |

## Edge Cases
- Uncomplete a completed step

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
