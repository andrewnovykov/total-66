# TC-203: Guest Cannot Like Goal

## Linked User Story
- [US-200](../USER-STORY/US-200-goal-likes.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is not logged in
- Goal is public

## Test Steps
1. Navigate to public goal detail as guest
2. Attempt to find/click Like button

## Expected Results
- Like button is hidden or prompts login
- Clicking redirects to login page
- Like count is visible but not interactive

## Test Data
| Field | Value |
|-------|-------|
| user_role | guest |

## Edge Cases
- Direct API like attempt

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
