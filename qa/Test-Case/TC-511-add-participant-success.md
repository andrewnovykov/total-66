# TC-511: Successfully Add Participant

## Linked User Story
- [US-503](../USER-STORY/US-503-add-participants.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Coach is logged in
- Draft template exists
- Valid user to add

## Test Steps
1. Navigate to template
2. Go to participants section
3. Search for user
4. Click "Add"
5. Verify participant added

## Expected Results
- Participant is added to list
- Count increases
- User appears in participant list

## Test Data
| Field | Value |
|-------|-------|
| participant | test_user |

## Edge Cases
- Add multiple at once

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/participant_live_test.exs`
