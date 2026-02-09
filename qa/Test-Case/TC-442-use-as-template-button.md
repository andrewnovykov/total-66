# TC-442: Use as Template Button Visible

## Linked User Story
- [US-411](../USER-STORY/US-411-use-challenge-as-template.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- User has completed a challenge

## Test Steps
1. Navigate to challenge history
2. View completed challenge
3. Look for "Use as Template" button

## Expected Results
- Button is visible on completed challenges
- Button is clickable
- Tooltip explains functionality

## Test Data
| Field | Value |
|-------|-------|
| challenge_status | completed |

## Edge Cases
- Failed challenge (should still have button)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
