# TC-200: Successfully Like a Goal

## Linked User Story
- [US-200](../USER-STORY/US-200-goal-likes.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- Goal is public
- User does not own the goal
- User has not liked the goal

## Test Steps
1. Navigate to public goal detail
2. Click Like button
3. Observe like count

## Expected Results
- Goal is liked
- Like count increases by 1
- Like button changes state (filled icon)
- Action persists after refresh

## Test Data
| Field | Value |
|-------|-------|
| goal_visibility | public |
| initial_likes | 5 |
| final_likes | 6 |

## Edge Cases
- Like goal with 0 likes

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
