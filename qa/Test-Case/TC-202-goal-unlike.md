# TC-202: Unlike a Previously Liked Goal

## Linked User Story
- [US-200](../USER-STORY/US-200-goal-likes.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User has previously liked the goal

## Test Steps
1. Navigate to liked goal detail
2. Click Like button (to unlike)
3. Observe like count

## Expected Results
- Like is removed
- Like count decreases by 1
- Like button changes state (unfilled icon)
- Change persists after refresh

## Test Data
| Field | Value |
|-------|-------|
| initial_likes | 6 |
| final_likes | 5 |

## Edge Cases
- Unlike immediately after liking

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
