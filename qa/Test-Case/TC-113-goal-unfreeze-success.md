# TC-113: Successfully Unfreeze Goal

## Linked User Story
- [US-103](../USER-STORY/US-103-goal-status-management.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User owns the goal
- Goal status is "frozen"
- User has capacity for active item

## Test Steps
1. Navigate to owned frozen goal detail
2. Click "Unfreeze Goal" button
3. Confirm unfreeze action

## Expected Results
- Goal status changes to "active"
- Goal counts toward active limit
- Edit options are enabled
- Unfreeze button becomes "Freeze"

## Test Data
| Field | Value |
|-------|-------|
| initial_status | frozen |
| final_status | active |

## Edge Cases
- Unfreeze when at 3 active items

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
