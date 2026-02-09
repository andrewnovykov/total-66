# TC-109: Successful Goal Deletion by Owner

## Linked User Story
- [US-102](../USER-STORY/US-102-goal-deletion.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User owns the goal

## Test Steps
1. Navigate to owned goal detail
2. Click Delete button
3. Confirm deletion in dialog

## Expected Results
- Goal is soft-deleted
- Goal removed from listings
- User redirected to My Goals
- Active item count decreases

## Test Data
| Field | Value |
|-------|-------|
| goal_id | 123 |

## Edge Cases
- Goal with many posts
- Goal with subscriptions

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
