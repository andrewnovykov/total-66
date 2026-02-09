# TC-112: Successfully Freeze Goal

## Linked User Story
- [US-103](../USER-STORY/US-103-goal-status-management.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User owns the goal
- Goal status is "active"

## Test Steps
1. Navigate to owned goal detail
2. Click "Freeze Goal" button
3. Confirm freeze action

## Expected Results
- Goal status changes to "frozen"
- Goal no longer counts toward active limit
- Edit options are disabled
- Freeze button becomes "Unfreeze"

## Test Data
| Field | Value |
|-------|-------|
| initial_status | active |
| final_status | frozen |

## Edge Cases
- Freeze goal with incomplete steps

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
