# TC-110: Goal Deletion Denied for Non-Owner

## Linked User Story
- [US-102](../USER-STORY/US-102-goal-deletion.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- User is logged in
- User does NOT own the goal

## Test Steps
1. Navigate to another user's goal detail
2. Attempt to find Delete button
3. Attempt API-level deletion

## Expected Results
- Delete button is not visible
- API deletion returns 403
- Goal remains unchanged

## Test Data
| Field | Value |
|-------|-------|
| goal_owner | other_user |
| current_user | test_user |

## Edge Cases
- Admin privileges
- Soft-deleted goal

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
