# TC-645: Friends List Search

## Linked User Story
- [US-608](../USER-STORY/US-608-friends-list.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- User has many friends
- Friends list is open

## Test Steps
1. Open friends list
2. Enter search term in search field
3. Observe filtered results
4. Clear search to see all friends

## Expected Results
- Search filters friends by name/username
- Partial matches work
- Case insensitive
- Clear restores full list

## Test Data
| Field | Value |
|-------|-------|
| search_term | john |
| total_friends | 20 |
| matched_friends | 2 |

## Edge Cases
- No search results

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
