# TC-515: Successfully Start Group Goal

## Linked User Story
- [US-504](../USER-STORY/US-504-start-group-goal.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- Coach is logged in
- Template with participants exists

## Test Steps
1. Navigate to template
2. Click "Start Group Goal"
3. Confirm in dialog
4. Observe result

## Expected Results
- Group goal starts
- Status changes to "active"
- Participants receive goal instances
- Dashboard updates

## Test Data
| Field | Value |
|-------|-------|
| participants | 5 |
| status | active |

## Edge Cases
- No participants

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/group_goal_live_test.exs`
