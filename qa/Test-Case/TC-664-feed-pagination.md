# TC-664: Feed Pagination

## Linked User Story
- [US-612](../USER-STORY/US-612-social-feed.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User has many items in feed
- Feed page loaded

## Test Steps
1. Load feed page
2. Scroll to end of initial items
3. Trigger load more (scroll/button)
4. Observe additional items load
5. Continue to end of feed

## Expected Results
- Initial page loads quickly
- Infinite scroll or pagination works
- More items load on demand
- End of feed indicated
- No duplicate items

## Test Data
| Field | Value |
|-------|-------|
| total_feed_items | 100 |
| page_size | 20 |

## Edge Cases
- Exactly one page of items

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/feed_live_test.exs`
