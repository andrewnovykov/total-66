# TC-214: Cannot Like Own Post

## Linked User Story
- [US-203](../USER-STORY/US-203-post-likes.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User created the post

## Test Steps
1. Navigate to own post
2. Attempt to find/click Like button

## Expected Results
- Like button is hidden/disabled for own posts
- Cannot like via API
- Error if attempted

## Test Data
| Field | Value |
|-------|-------|
| post_owner | current_user |

## Edge Cases
- API-level attempt

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_post_live_test.exs`
