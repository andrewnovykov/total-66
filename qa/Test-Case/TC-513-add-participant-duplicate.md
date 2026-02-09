# TC-513: Cannot Add Duplicate Participant

## Linked User Story
- [US-503](../USER-STORY/US-503-add-participants.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Coach is logged in
- Participant already added

## Test Steps
1. Navigate to participants
2. Search for already-added user
3. Attempt to add again

## Expected Results
- Add button disabled/hidden
- Message: "Already added"
- No duplicate created

## Test Data
| Field | Value |
|-------|-------|
| existing_participant | test_user |

## Edge Cases
- Removed then re-added

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/participant_live_test.exs`
