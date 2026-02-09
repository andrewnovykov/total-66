# TC-414: Task Schedule - Custom Weekdays

## Linked User Story
- [US-403](../USER-STORY/US-403-challenge-task-scheduling.md)

## Test Type
Integration

## Priority
Medium

## Preconditions
- Challenge exists with custom weekday task (Mon/Wed/Fri)

## Test Steps
1. View challenge on Monday - task appears
2. View challenge on Tuesday - no task
3. View challenge on Wednesday - task appears
4. View challenge on Thursday - no task
5. View challenge on Friday - task appears

## Expected Results
- Task appears only on selected days
- Other days show no task
- Pattern repeats weekly

## Test Data
| Field | Value |
|-------|-------|
| recurrence_type | custom |
| custom_days | [monday, wednesday, friday] |

## Edge Cases
- Single day selected

## Automation Status
- [ ] Automated in: `test/heads_up/challenges_test.exs`
