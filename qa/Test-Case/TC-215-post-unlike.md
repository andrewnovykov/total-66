# TC-215: Unlike a Post

## Linked User Story
- [US-203](../USER-STORY/US-203-post-likes.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- User is logged in
- User has liked the post

## Test Steps
1. Navigate to liked post
2. Click Like button (to unlike)
3. Observe like count

## Expected Results
- Like is removed
- Like count decreases
- Button state changes

## Test Data
| Field | Value |
|-------|-------|
| initially_liked | true |

## Edge Cases
- Unlike immediately after liking

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_post_live_test.exs`
