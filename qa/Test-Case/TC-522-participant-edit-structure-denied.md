# TC-522: Participant Cannot Edit Goal Structure

## Linked User Story
- [US-505](../USER-STORY/US-505-participant-goal-instance.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- Participant has goal instance

## Test Steps
1. Navigate to goal instance
2. Look for edit structure options
3. Attempt API edit

## Expected Results
- No edit structure buttons
- Cannot add/remove phases
- Cannot add/remove steps
- Only completion actions

## Test Data
| Field | Value |
|-------|-------|
| user_role | participant |

## Edge Cases
- API edit attempt

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
