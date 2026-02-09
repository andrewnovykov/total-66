# TC-443: Use as Template Creates Copy

## Linked User Story
- [US-411](../USER-STORY/US-411-use-challenge-as-template.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- User has completed a challenge

## Test Steps
1. Navigate to completed challenge
2. Click "Use as Template"
3. Confirm action
4. View new challenge

## Expected Results
- New custom challenge created
- Structure copied from original
- Progress starts at 0%
- Counts as new active item

## Test Data
| Field | Value |
|-------|-------|
| original_tasks | 5 |
| new_tasks | 5 |
| new_progress | 0% |

## Edge Cases
- Already at max active items

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
