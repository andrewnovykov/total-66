# TC-221: Feed Pagination

## Linked User Story
- [US-205](../USER-STORY/US-205-user-feed.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Feed has many posts (50+)

## Test Steps
1. Navigate to feed
2. Scroll to bottom
3. Load more posts
4. Continue scrolling

## Expected Results
- Initial load shows limited posts
- Scrolling loads more posts
- Performance remains smooth
- No duplicate posts

## Test Data
| Field | Value |
|-------|-------|
| total_posts | 50+ |
| page_size | 20 |

## Edge Cases
- Fast scrolling
- End of feed

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/feed_live_test.exs`
