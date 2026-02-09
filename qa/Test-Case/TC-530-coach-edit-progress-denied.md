# TC-530: Coach Cannot Edit Participant Progress

## Linked User Story
- [US-507](../USER-STORY/US-507-participant-progress-tracking.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- Coach viewing participant detail

## Test Steps
1. Navigate to participant detail
2. Look for edit progress options
3. Attempt API edit

## Expected Results
- No edit buttons for progress
- Read-only view only
- API returns 403

## Test Data
| Field | Value |
|-------|-------|
| user_role | coach |

## Edge Cases
- Admin coach

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/participant_live_test.exs`
