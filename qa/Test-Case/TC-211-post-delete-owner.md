# TC-211: Delete Own Post

## Linked User Story
- [US-202](../USER-STORY/US-202-goal-posts.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User created the post

## Test Steps
1. Navigate to post
2. Click Delete button
3. Confirm deletion

## Expected Results
- Post is removed
- Post no longer in goal feed
- Associated comments removed

## Test Data
| Field | Value |
|-------|-------|
| post_owner | current_user |

## Edge Cases
- Delete post with many comments

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_post_live_test.exs`
