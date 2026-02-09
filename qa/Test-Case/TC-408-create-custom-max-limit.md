# TC-408: Cannot Create Custom Challenge at Max Limit

## Linked User Story
- [US-402](../USER-STORY/US-402-create-custom-challenge.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- User is logged in
- User has exactly 3 active items

## Test Steps
1. Navigate to challenges page
2. Attempt to click "Create Challenge"

## Expected Results
- Create button is disabled or hidden
- Message shows limit reached
- Cannot create new challenge

## Test Data
| Field | Value |
|-------|-------|
| active_items | 3 |

## Edge Cases
- Limit from mix of goals and challenges

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
