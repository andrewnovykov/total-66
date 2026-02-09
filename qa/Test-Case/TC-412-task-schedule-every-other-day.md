# TC-412: Task Schedule - Every Other Day

## Linked User Story
- [US-403](../USER-STORY/US-403-challenge-task-scheduling.md)

## Test Type
Integration

## Priority
Medium

## Preconditions
- Challenge exists with every-other-day task

## Test Steps
1. View challenge on day 1 - task appears
2. View challenge on day 2 - no task
3. View challenge on day 3 - task appears
4. Verify alternating pattern

## Expected Results
- Task appears on alternating days
- Pattern is consistent
- Based on challenge start date

## Test Data
| Field | Value |
|-------|-------|
| recurrence_type | every_other_day |

## Edge Cases
- Month boundary

## Automation Status
- [ ] Automated in: `test/heads_up/challenges_test.exs`
