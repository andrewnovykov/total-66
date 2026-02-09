# TC-428: Predefined Challenge API Edit Denied

## Linked User Story
- [US-407](../USER-STORY/US-407-predefined-challenge-readonly.md)

## Test Type
Integration

## Priority
Critical

## Preconditions
- User has joined predefined challenge

## Test Steps
1. Attempt API call to edit predefined challenge
2. Observe response

## Expected Results
- API returns 403 Forbidden
- Challenge remains unchanged
- Error message returned

## Test Data
| Field | Value |
|-------|-------|
| challenge_type | predefined |
| edit_attempt | API |

## Edge Cases
- Participant vs non-participant

## Automation Status
- [ ] Automated in: `test/heads_up/challenges_test.exs`
