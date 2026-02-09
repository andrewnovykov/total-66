# TC-507: Successfully Edit Template

## Linked User Story
- [US-502](../USER-STORY/US-502-edit-group-goal-template.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Coach is logged in
- Draft template exists

## Test Steps
1. Navigate to template list
2. Click edit on draft template
3. Change title
4. Update description
5. Save changes

## Expected Results
- Template is updated
- Changes are saved
- Updated values displayed

## Test Data
| Field | Value |
|-------|-------|
| old_title | Old Title |
| new_title | Updated Title |

## Edge Cases
- Edit with no changes

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/template_live_test.exs`
