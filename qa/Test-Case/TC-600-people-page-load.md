# TC-600: People Page Load

## Linked User Story
- [US-600](../USER-STORY/US-600-people-directory.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Application is running
- People exist in database

## Test Steps
1. Navigate to /people
2. Wait for page to load
3. Observe page content

## Expected Results
- Page loads successfully
- Search bar visible
- User cards displayed
- Pagination controls visible

## Test Data
| Field | Value |
|-------|-------|
| url | /people |

## Edge Cases
- No users in database
- Slow network connection

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
