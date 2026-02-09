# TC-102: Goal Creation at Maximum Limit

## Linked User Story
- [US-100](../USER-STORY/US-100-goal-creation.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- User is logged in
- User has exactly 3 active items

## Test Steps
1. Navigate to My Goals
2. Attempt to click "Create Goal"

## Expected Results
- Create button is disabled or hidden
- Message shows: "Maximum active items reached"
- User cannot create new goal

## Test Data
| Field | Value |
|-------|-------|
| active_items | 3 |

## Edge Cases
- 2 goals + 1 challenge
- 1 goal + 1 challenge + 1 group goal

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
