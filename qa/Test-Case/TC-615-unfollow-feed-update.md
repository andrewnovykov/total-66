# TC-615: Unfollow Removes from Feed

## Linked User Story
- [US-602](../USER-STORY/US-602-unfollow-user.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in and following target
- Target user has posts in feed

## Test Steps
1. View feed with target user's posts
2. Unfollow target user
3. Refresh feed
4. Check for target user's content

## Expected Results
- Target user's posts no longer in feed
- Feed updates on next refresh
- Other followed users' content remains

## Test Data
| Field | Value |
|-------|-------|
| unfollowed_user | target_user |
| feed_content | target_user_posts |

## Edge Cases
- Target user's content already cached

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/feed_live_test.exs`
