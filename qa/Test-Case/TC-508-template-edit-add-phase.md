# TC-508: Add Phase to Existing Template

## Linked User Story
- [US-502](../USER-STORY/US-502-edit-group-goal-template.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Coach is logged in
- Draft template with phases exists

## Test Steps
1. Navigate to template edit
2. Click "Add Phase"
3. Enter phase title
4. Add steps to new phase
5. Save changes

## Expected Results
- New phase is added
- Phase order updated
- Steps are saved

## Test Data
| Field | Value |
|-------|-------|
| initial_phases | 2 |
| final_phases | 3 |

## Edge Cases
- Reorder phases

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/template_live_test.exs`
