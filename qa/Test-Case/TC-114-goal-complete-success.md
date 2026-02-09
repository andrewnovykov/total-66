# TC-114: Mark Goal as Completed

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
2. Click "Mark Complete" button
3. Confirm completion

## Expected Results
- Goal status changes to "completed"
- Goal no longer counts toward active limit
- Completion is celebrated (animation/message)
- Goal moves to completed section

## Test Data
| Field | Value |
|-------|-------|
| initial_status | active |
| final_status | completed |

## Edge Cases
- Complete goal with incomplete steps

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
