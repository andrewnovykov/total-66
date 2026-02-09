# TC-405: Cannot Join Already Active Challenge

## Linked User Story
- [US-401](../USER-STORY/US-401-join-predefined-challenge.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User already has this challenge active

## Test Steps
1. Navigate to challenges page
2. Find challenge user has already joined
3. Observe button state

## Expected Results
- Button shows "Already Joined" or similar
- Cannot join same challenge twice
- Link to active challenge provided

## Test Data
| Field | Value |
|-------|-------|
| challenge_status | active |

## Edge Cases
- Previously completed same challenge

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
