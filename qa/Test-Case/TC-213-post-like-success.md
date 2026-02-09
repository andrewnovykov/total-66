# TC-213: Successfully Like a Post

## Linked User Story
- [US-203](../USER-STORY/US-203-post-likes.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User does not own the post
- Post is on a visible goal

## Test Steps
1. Navigate to goal with posts
2. Click Like on a post
3. Observe like count

## Expected Results
- Post is liked
- Like count increases
- Like button state changes

## Test Data
| Field | Value |
|-------|-------|
| post_owner | other_user |

## Edge Cases
- Like post immediately after creation

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_post_live_test.exs`
