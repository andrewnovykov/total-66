# TC-416: Uncomplete a Task

## Linked User Story
- [US-404](../USER-STORY/US-404-complete-challenge-task.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Task is already completed

## Test Steps
1. Navigate to challenge detail
2. Find completed task
3. Click to uncomplete
4. Observe status change

## Expected Results
- Task marked as incomplete
- Checkbox is unchecked
- Progress recalculated

## Test Data
| Field | Value |
|-------|-------|
| initial_status | completed |
| final_status | incomplete |

## Edge Cases
- Uncomplete after progress reward

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
