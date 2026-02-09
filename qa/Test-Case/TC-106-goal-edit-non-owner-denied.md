# TC-106: Goal Edit Denied for Non-Owner

## Linked User Story
- [US-101](../USER-STORY/US-101-goal-editing.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- User is logged in
- User does NOT own the goal

## Test Steps
1. Navigate to another user's goal detail
2. Attempt to find Edit button

## Expected Results
- Edit button is not visible
- Direct URL access to edit page is denied
- 403 or redirect response

## Test Data
| Field | Value |
|-------|-------|
| goal_owner | other_user |
| current_user | test_user |

## Edge Cases
- Admin attempting to edit
- API-level edit attempt

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
