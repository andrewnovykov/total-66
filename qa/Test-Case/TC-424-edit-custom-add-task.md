# TC-424: Add Task to Custom Challenge

## Linked User Story
- [US-406](../USER-STORY/US-406-edit-custom-challenge.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User owns custom challenge

## Test Steps
1. Navigate to owned custom challenge
2. Click Edit button
3. Add new task with schedule
4. Save changes

## Expected Results
- Task is added
- Task appears in challenge
- Schedule is applied

## Test Data
| Field | Value |
|-------|-------|
| new_task | Meditate |
| schedule | daily |

## Edge Cases
- Add task with same name

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
