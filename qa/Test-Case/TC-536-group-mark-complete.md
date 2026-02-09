# TC-536: Mark Group Goal Complete

## Linked User Story
- [US-509](../USER-STORY/US-509-group-goal-completion.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Coach is logged in
- Group goal is active

## Test Steps
1. Navigate to group goal
2. Click "Complete Group Goal"
3. Confirm completion

## Expected Results
- Group goal status changes to completed
- Moves to history/archive
- Summary statistics generated

## Test Data
| Field | Value |
|-------|-------|
| initial_status | active |
| final_status | completed |

## Edge Cases
- Complete with incomplete participants

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/group_goal_live_test.exs`
