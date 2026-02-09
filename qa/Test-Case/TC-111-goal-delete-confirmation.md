# TC-111: Goal Deletion Requires Confirmation

## Linked User Story
- [US-102](../USER-STORY/US-102-goal-deletion.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User owns the goal

## Test Steps
1. Navigate to owned goal detail
2. Click Delete button
3. Click Cancel in confirmation dialog

## Expected Results
- Deletion is cancelled
- Goal remains active
- User returns to goal detail

## Test Data
| Field | Value |
|-------|-------|
| goal_id | 123 |

## Edge Cases
- Click outside dialog

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
