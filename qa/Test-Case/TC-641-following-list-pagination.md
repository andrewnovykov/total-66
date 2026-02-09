# TC-641: Following List Pagination

## Linked User Story
- [US-607](../USER-STORY/US-607-followers-following-list.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- User follows many users (more than page size)

## Test Steps
1. Open following list
2. Scroll or click load more
3. Observe additional users load
4. Continue to end of list

## Expected Results
- Initial page loads quickly
- Load more adds users
- No duplicates shown
- End of list indicated

## Test Data
| Field | Value |
|-------|-------|
| total_following | 50 |
| page_size | 20 |

## Edge Cases
- Exactly one page of users

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
