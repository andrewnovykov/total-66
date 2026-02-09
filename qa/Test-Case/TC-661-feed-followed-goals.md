# TC-661: Feed Shows Followed Goals Updates

## Linked User Story
- [US-612](../USER-STORY/US-612-social-feed.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User follows specific goals with updates

## Test Steps
1. Follow a goal
2. Goal owner posts update
3. Navigate to feed
4. Verify goal update appears

## Expected Results
- Followed goal updates in feed
- Shows posts related to goal
- Shows step completions
- Goal context visible in feed item

## Test Data
| Field | Value |
|-------|-------|
| followed_goals | 3 |
| feed_content | goal_updates |

## Edge Cases
- Goal deleted after follow

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/feed_live_test.exs`
