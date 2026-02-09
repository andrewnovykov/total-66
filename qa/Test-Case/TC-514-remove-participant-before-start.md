# TC-514: Remove Participant Before Start

## Linked User Story
- [US-503](../USER-STORY/US-503-add-participants.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Coach is logged in
- Participant added to draft template

## Test Steps
1. Navigate to participants
2. Find participant to remove
3. Click remove button
4. Confirm removal

## Expected Results
- Participant is removed
- Count decreases
- User no longer in list

## Test Data
| Field | Value |
|-------|-------|
| initial_participants | 5 |
| final_participants | 4 |

## Edge Cases
- Remove all participants

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/participant_live_test.exs`
