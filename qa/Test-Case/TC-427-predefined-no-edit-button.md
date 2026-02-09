# TC-427: Predefined Challenge Has No Edit Button

## Linked User Story
- [US-407](../USER-STORY/US-407-predefined-challenge-readonly.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User has joined predefined challenge

## Test Steps
1. Navigate to joined predefined challenge
2. Look for Edit button

## Expected Results
- Edit button is NOT visible
- Only completion actions available
- Challenge structure is read-only

## Test Data
| Field | Value |
|-------|-------|
| challenge_type | predefined |

## Edge Cases
- Admin viewing predefined

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
