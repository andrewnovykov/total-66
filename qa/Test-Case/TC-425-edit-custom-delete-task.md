# TC-425: Delete Task from Custom Challenge

## Linked User Story
- [US-406](../USER-STORY/US-406-edit-custom-challenge.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User owns custom challenge with multiple tasks

## Test Steps
1. Navigate to owned custom challenge
2. Click Edit button
3. Delete a task
4. Confirm deletion
5. Save changes

## Expected Results
- Task is removed
- Other tasks remain
- Progress recalculated

## Test Data
| Field | Value |
|-------|-------|
| initial_tasks | 3 |
| final_tasks | 2 |

## Edge Cases
- Delete last task

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
