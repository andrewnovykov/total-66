# TC-517: Template Becomes Read-Only After Start

## Linked User Story
- [US-504](../USER-STORY/US-504-start-group-goal.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Group goal just started

## Test Steps
1. Navigate to started group goal
2. Attempt to access template edit
3. Observe result

## Expected Results
- Template is read-only
- Edit options disabled
- Cannot modify structure

## Test Data
| Field | Value |
|-------|-------|
| group_status | active |

## Edge Cases
- API edit attempt

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/group_goal_live_test.exs`
