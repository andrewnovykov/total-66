# TC-411: Task Schedule - Twice a Week

## Linked User Story
- [US-403](../USER-STORY/US-403-challenge-task-scheduling.md)

## Test Type
Integration

## Priority
Medium

## Preconditions
- Challenge exists with twice-week task

## Test Steps
1. View challenge throughout week
2. Count days task appears
3. Verify 2 appearances per week

## Expected Results
- Task appears exactly 2 days per week
- Days are reasonably spaced
- Pattern repeats weekly

## Test Data
| Field | Value |
|-------|-------|
| recurrence_type | twice_week |

## Edge Cases
- Week boundary handling

## Automation Status
- [ ] Automated in: `test/heads_up/challenges_test.exs`
