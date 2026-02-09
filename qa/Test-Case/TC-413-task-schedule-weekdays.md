# TC-413: Task Schedule - Weekdays (Mon-Fri)

## Linked User Story
- [US-403](../USER-STORY/US-403-challenge-task-scheduling.md)

## Test Type
Integration

## Priority
Medium

## Preconditions
- Challenge exists with Mon-Fri task

## Test Steps
1. View challenge on Monday - task appears
2. View challenge on Saturday - no task
3. View challenge on Sunday - no task
4. View challenge on Tuesday - task appears

## Expected Results
- Task appears Mon-Fri only
- No task on weekends
- Pattern repeats weekly

## Test Data
| Field | Value |
|-------|-------|
| recurrence_type | weekdays |

## Edge Cases
- Holiday handling (if applicable)

## Automation Status
- [ ] Automated in: `test/heads_up/challenges_test.exs`
