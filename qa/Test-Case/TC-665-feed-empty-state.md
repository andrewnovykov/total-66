# TC-665: Feed Empty State

## Linked User Story
- [US-612](../USER-STORY/US-612-social-feed.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User follows no one or followed have no activity

## Test Steps
1. Create new user (follows no one)
2. Navigate to feed
3. Observe empty state
4. Check for helpful message and CTA

## Expected Results
- Empty feed message shown
- Suggests following users/goals
- Link to discover people/goals
- Clean, helpful UI

## Test Data
| Field | Value |
|-------|-------|
| followed_count | 0 |
| feed_items | 0 |
| expected_message | Follow users to see updates |

## Edge Cases
- User unfollows everyone

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/feed_live_test.exs`
