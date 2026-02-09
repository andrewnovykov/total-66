# TC-201: Cannot Like Own Goal

## Linked User Story
- [US-200](../USER-STORY/US-200-goal-likes.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- User is logged in
- User owns the goal

## Test Steps
1. Navigate to owned goal detail
2. Look for Like button

## Expected Results
- Like button is hidden or disabled
- Cannot like own goal via API
- Error if attempted: "Cannot like your own goal"

## Test Data
| Field | Value |
|-------|-------|
| goal_owner | current_user |

## Edge Cases
- API-level like attempt

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
