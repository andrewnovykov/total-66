# TC-404: Cannot Join Challenge at Max Active Items

## Linked User Story
- [US-401](../USER-STORY/US-401-join-predefined-challenge.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- User is logged in
- User has exactly 3 active items

## Test Steps
1. Navigate to challenges page
2. Attempt to click "Join" on a challenge

## Expected Results
- Join button is disabled or hidden
- Message shows: "Maximum active items reached"
- Cannot join any new challenge

## Test Data
| Field | Value |
|-------|-------|
| active_items | 3 |

## Edge Cases
- 2 goals + 1 challenge

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
