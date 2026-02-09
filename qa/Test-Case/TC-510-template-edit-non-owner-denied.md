# TC-510: Non-Owner Cannot Edit Template

## Linked User Story
- [US-502](../USER-STORY/US-502-edit-group-goal-template.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Coach is logged in
- Template owned by different coach

## Test Steps
1. Attempt to access another coach's template
2. Attempt API edit

## Expected Results
- Edit access denied
- 403 or redirect response
- Template unchanged

## Test Data
| Field | Value |
|-------|-------|
| template_owner | other_coach |
| current_user | test_coach |

## Edge Cases
- Admin access

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/template_live_test.exs`
