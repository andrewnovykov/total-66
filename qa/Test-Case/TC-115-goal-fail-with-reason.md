# TC-115: Mark Goal as Failed with Reason

## Linked User Story
- [US-103](../USER-STORY/US-103-goal-status-management.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User owns the goal

## Test Steps
1. Navigate to owned goal detail
2. Click "Fail Goal" button
3. Enter failure reason: "Priorities changed"
4. Confirm failure

## Expected Results
- Goal status changes to "failed"
- Failure reason is saved
- Goal no longer counts toward active limit
- Reason displayed in goal history

## Test Data
| Field | Value |
|-------|-------|
| failure_reason | Priorities changed |
| final_status | failed |

## Edge Cases
- Very long failure reason

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
