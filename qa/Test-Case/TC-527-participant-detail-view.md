# TC-527: Participant Detail View

## Linked User Story
- [US-507](../USER-STORY/US-507-participant-progress-tracking.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Coach is logged in
- Participant has activity

## Test Steps
1. Navigate to participant list
2. Click on participant
3. View detail page

## Expected Results
- Full progress details shown
- Step completion list
- Activity timeline
- Last activity date

## Test Data
| Field | Value |
|-------|-------|
| participant | test_user |

## Edge Cases
- Participant with no activity

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/participant_live_test.exs`
