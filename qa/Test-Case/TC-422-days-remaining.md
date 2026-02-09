# TC-422: Days Remaining Display

## Linked User Story
- [US-405](../USER-STORY/US-405-challenge-progress-tracking.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- User has active timed challenge
- Challenge has known duration

## Test Steps
1. Navigate to challenge detail
2. View days remaining
3. Wait one day
4. Verify count decreased

## Expected Results
- Days remaining is displayed
- Count decreases daily
- Shows 0 on last day

## Test Data
| Field | Value |
|-------|-------|
| duration | 30 days |
| started | 10 days ago |
| remaining | 20 days |

## Edge Cases
- Challenge with no end date

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
