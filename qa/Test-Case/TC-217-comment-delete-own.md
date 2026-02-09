# TC-217: Delete Own Comment

## Linked User Story
- [US-204](../USER-STORY/US-204-post-comments.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User created the comment

## Test Steps
1. Navigate to own comment
2. Click Delete button
3. Confirm deletion

## Expected Results
- Comment is removed
- Comment count decreases
- No trace of comment remains

## Test Data
| Field | Value |
|-------|-------|
| comment_owner | current_user |

## Edge Cases
- Delete immediately after posting

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_post_live_test.exs`
