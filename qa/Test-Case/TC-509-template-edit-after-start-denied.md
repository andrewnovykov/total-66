# TC-509: Cannot Edit Template After Start

## Linked User Story
- [US-502](../USER-STORY/US-502-edit-group-goal-template.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- Coach is logged in
- Group goal has been started

## Test Steps
1. Navigate to active group goal's template
2. Attempt to find edit options

## Expected Results
- Edit buttons are disabled/hidden
- Template is read-only
- Message explains why

## Test Data
| Field | Value |
|-------|-------|
| group_goal_status | active |

## Edge Cases
- API edit attempt

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/template_live_test.exs`
