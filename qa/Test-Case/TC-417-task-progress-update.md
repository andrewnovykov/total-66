# TC-417: Task Completion Updates Progress

## Linked User Story
- [US-404](../USER-STORY/US-404-complete-challenge-task.md)

## Test Type
Integration

## Priority
High

## Preconditions
- Challenge with 10 tasks
- 0 tasks completed

## Test Steps
1. Complete 1 task
2. Check progress percentage
3. Complete 4 more tasks
4. Check progress percentage

## Expected Results
- Progress updates after each completion
- 1/10 = 10%
- 5/10 = 50%
- Progress bar reflects changes

## Test Data
| Field | Value |
|-------|-------|
| total_tasks | 10 |
| completed_1 | 10% |
| completed_5 | 50% |

## Edge Cases
- All tasks completed = 100%

## Automation Status
- [ ] Automated in: `test/heads_up/challenges_test.exs`
