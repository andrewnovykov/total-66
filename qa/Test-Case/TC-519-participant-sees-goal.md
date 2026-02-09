# TC-519: Participant Sees Goal Instance

## Linked User Story
- [US-505](../USER-STORY/US-505-participant-goal-instance.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- Group goal has started
- Participant is logged in

## Test Steps
1. Navigate to My Goals
2. Look for group goal instance
3. View goal details

## Expected Results
- Goal appears in My Goals
- Goal shows group goal indicator
- Phases and steps visible
- Progress at 0%

## Test Data
| Field | Value |
|-------|-------|
| user_role | participant |

## Edge Cases
- Participant not aware of group

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
