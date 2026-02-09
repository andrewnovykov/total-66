# TC-503: Successfully Create Template

## Linked User Story
- [US-501](../USER-STORY/US-501-create-group-goal-template.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- Coach is logged in

## Test Steps
1. Navigate to Coach Center
2. Click "Create Template"
3. Enter title: "30-Day Fitness Program"
4. Add description
5. Select category
6. Add at least one phase with steps
7. Save as draft

## Expected Results
- Template is created
- Template appears in templates list
- Status is "draft"
- Can be edited

## Test Data
| Field | Value |
|-------|-------|
| title | 30-Day Fitness Program |
| description | Complete fitness transformation |
| category | Fitness |
| phases | 3 |

## Edge Cases
- Minimal template (title only)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/template_live_test.exs`
