# TC-504: Template Creation Missing Title

## Linked User Story
- [US-501](../USER-STORY/US-501-create-group-goal-template.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Coach is logged in

## Test Steps
1. Navigate to template creation
2. Leave title empty
3. Fill other fields
4. Attempt to save

## Expected Results
- Creation fails
- Error message: "Title can't be blank"
- User remains on form

## Test Data
| Field | Value |
|-------|-------|
| title | (empty) |

## Edge Cases
- Whitespace-only title

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/template_live_test.exs`
