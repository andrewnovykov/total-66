# TC-101: Goal Creation with Missing Title

## Linked User Story
- [US-100](../USER-STORY/US-100-goal-creation.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in

## Test Steps
1. Navigate to goal creation form
2. Leave title empty
3. Fill other fields
4. Click Save

## Expected Results
- Goal creation fails
- Error message: "Title can't be blank"
- User remains on creation form

## Test Data
| Field | Value |
|-------|-------|
| title | (empty) |
| description | Some description |

## Edge Cases
- Whitespace-only title

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
