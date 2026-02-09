# TC-506: Save Template as Draft

## Linked User Story
- [US-501](../USER-STORY/US-501-create-group-goal-template.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Coach is logged in

## Test Steps
1. Create template with basic info
2. Click "Save as Draft"
3. Navigate away
4. Return to templates

## Expected Results
- Template saved with draft status
- Template appears in list
- Can continue editing later
- Not visible to participants

## Test Data
| Field | Value |
|-------|-------|
| status | draft |

## Edge Cases
- Incomplete template saved

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/template_live_test.exs`
