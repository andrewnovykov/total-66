# TC-437: Today's Tasks Display

## Linked User Story
- [US-409](../USER-STORY/US-409-my-challenges-dashboard.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User has active challenge with today's tasks

## Test Steps
1. Navigate to My Challenges
2. View today's tasks section
3. Check tasks listed

## Expected Results
- Today's tasks prominently shown
- Completion status indicated
- Quick complete actions available
- Count of remaining tasks shown

## Test Data
| Field | Value |
|-------|-------|
| todays_tasks | 3 |
| completed | 1 |
| remaining | 2 |

## Edge Cases
- No tasks today
- All tasks completed

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
