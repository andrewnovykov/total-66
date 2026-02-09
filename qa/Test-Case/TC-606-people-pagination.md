# TC-606: People Pagination

## Linked User Story
- [US-600](../USER-STORY/US-600-people-directory.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- More than one page of users exist
- User is on /people page

## Test Steps
1. Observe initial page of results
2. Click "Load more" or next page
3. Observe additional users load
4. Continue until end of results

## Expected Results
- Initial page shows limited users
- Load more adds more users
- End of results indicated
- No duplicate users shown

## Test Data
| Field | Value |
|-------|-------|
| page_size | 20 |
| total_users | 50 |

## Edge Cases
- Exactly one page of users
- Empty results

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
