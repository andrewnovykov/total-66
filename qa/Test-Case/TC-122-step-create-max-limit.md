# TC-122: Step Creation at Maximum Limit

## Linked User Story
- [US-105](../USER-STORY/US-105-goal-steps.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User owns the goal
- Goal has exactly 20 steps

## Test Steps
1. Navigate to owned goal detail
2. Attempt to click "Add Step"

## Expected Results
- Add Step button is disabled or hidden
- Message shows: "Maximum steps reached"
- Cannot add more steps

## Test Data
| Field | Value |
|-------|-------|
| current_steps | 20 |

## Edge Cases
- Delete step then add new one

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
