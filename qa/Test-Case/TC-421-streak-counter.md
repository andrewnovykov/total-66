# TC-421: Streak Counter

## Linked User Story
- [US-405](../USER-STORY/US-405-challenge-progress-tracking.md)

## Test Type
Integration

## Priority
Medium

## Preconditions
- User has active challenge
- Multiple days of activity

## Test Steps
1. Complete all tasks on day 1
2. Complete all tasks on day 2
3. Complete all tasks on day 3
4. Check streak counter

## Expected Results
- Streak shows 3 days
- Counter increments daily
- Missed day resets streak

## Test Data
| Field | Value |
|-------|-------|
| consecutive_days | 3 |
| streak | 3 |

## Edge Cases
- Streak after miss
- Very long streak

## Automation Status
- [ ] Automated in: `test/heads_up/challenges_test.exs`
