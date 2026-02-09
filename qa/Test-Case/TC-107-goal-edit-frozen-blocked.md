# TC-107: Edit Blocked for Frozen Goal

## Linked User Story
- [US-101](../USER-STORY/US-101-goal-editing.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User owns the goal
- Goal status is "frozen"

## Test Steps
1. Navigate to owned frozen goal detail
2. Attempt to click Edit button

## Expected Results
- Edit button is disabled or hidden
- Message indicates goal is frozen
- Must unfreeze before editing

## Test Data
| Field | Value |
|-------|-------|
| goal_status | frozen |

## Edge Cases
- Recently frozen goal

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
