# TC-409: Create Custom Challenge with Multiple Tasks

## Linked User Story
- [US-402](../USER-STORY/US-402-create-custom-challenge.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in

## Test Steps
1. Navigate to create challenge form
2. Enter title
3. Add task 1: "Wake up at 6am" - daily
4. Add task 2: "Exercise" - Mon/Wed/Fri
5. Add task 3: "Read" - every-other-day
6. Save challenge

## Expected Results
- Challenge created with all tasks
- Each task has correct schedule
- Tasks appear in challenge detail

## Test Data
| Field | Value |
|-------|-------|
| task_1 | Wake up at 6am (daily) |
| task_2 | Exercise (Mon/Wed/Fri) |
| task_3 | Read (every-other-day) |

## Edge Cases
- Many tasks (10+)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
