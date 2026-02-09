# TC-220: Feed Shows Subscribed Goal Posts

## Linked User Story
- [US-205](../USER-STORY/US-205-user-feed.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User has subscribed to goals

## Test Steps
1. Navigate to user's feed
2. Review displayed posts

## Expected Results
- Posts from subscribed goals appear
- Posts ordered by recency
- Each post shows goal name
- Engagement metrics visible

## Test Data
| Field | Value |
|-------|-------|
| subscribed_goals | 3 |

## Edge Cases
- No subscriptions (empty state)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/feed_live_test.exs`
