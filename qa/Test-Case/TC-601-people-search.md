# TC-601: People Search

## Linked User Story
- [US-600](../USER-STORY/US-600-people-directory.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Multiple users exist with different names
- User is on /people page

## Test Steps
1. Enter search term in search bar
2. Observe results update
3. Clear search term
4. Observe results reset

## Expected Results
- Results filter by name or nickname
- Partial matches work
- Case insensitive search
- Clearing search shows all users

## Test Data
| Field | Value |
|-------|-------|
| search_term | john |
| expected_match | John Doe |

## Edge Cases
- No matching results
- Special characters in search
- Empty search term

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
