# TC-660: Feed Shows Followed Users Content

## Linked User Story
- [US-612](../USER-STORY/US-612-social-feed.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User follows other users with activity

## Test Steps
1. Navigate to feed page
2. Observe feed content
3. Identify posts from followed users
4. Verify only followed users' content shown

## Expected Results
- Feed contains followed users' posts
- Shows new goals from followed users
- Shows milestones and achievements
- Non-followed users not in feed

## Test Data
| Field | Value |
|-------|-------|
| followed_users | 5 |
| feed_content | followed_user_posts |

## Edge Cases
- Followed user has no recent activity

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/feed_live_test.exs`
