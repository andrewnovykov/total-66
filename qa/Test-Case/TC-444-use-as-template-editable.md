# TC-444: Template Copy is Editable

## Linked User Story
- [US-411](../USER-STORY/US-411-use-challenge-as-template.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- User has created challenge from template

## Test Steps
1. Navigate to new challenge (from template)
2. Click Edit button
3. Modify title
4. Add new task
5. Save changes

## Expected Results
- Challenge is fully editable
- Can modify title/description
- Can add/remove tasks
- Original template unchanged

## Test Data
| Field | Value |
|-------|-------|
| challenge_type | custom |
| editable | true |

## Edge Cases
- Edit copied from predefined

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
