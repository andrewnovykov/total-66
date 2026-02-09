# TC-410: Task Schedule - Daily

## Linked User Story
- [US-403](../USER-STORY/US-403-challenge-task-scheduling.md)

## Test Type
Integration

## Priority
High

## Preconditions
- Challenge exists with daily task

## Test Steps
1. View challenge on Monday
2. Check task appears
3. View challenge on Tuesday
4. Check task appears
5. Repeat for week

## Expected Results
- Task appears every day
- Task is due each day
- Completion resets daily

## Test Data
| Field | Value |
|-------|-------|
| recurrence_type | daily |

## Edge Cases
- Timezone handling

## Automation Status
- [ ] Automated in: `test/heads_up/challenges_test.exs`
