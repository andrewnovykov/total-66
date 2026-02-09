# TC-116: Fail Goal Requires Reason

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
3. Leave failure reason empty
4. Attempt to confirm

## Expected Results
- Failure is blocked
- Error message: "Failure reason is required"
- Goal status unchanged

## Test Data
| Field | Value |
|-------|-------|
| failure_reason | (empty) |

## Edge Cases
- Whitespace-only reason

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
