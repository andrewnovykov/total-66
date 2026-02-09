# TC-301: Admin User Search

## Linked User Story
- [US-300](../USER-STORY/US-300-admin-user-management.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Admin user is logged in
- Multiple users exist

## Test Steps
1. Navigate to admin users page
2. Enter search query: "john"
3. Press Enter or click Search
4. View filtered results

## Expected Results
- Results filtered by name/email
- Matching users displayed
- Clear search resets list

## Test Data
| Field | Value |
|-------|-------|
| search_query | john |

## Edge Cases
- No matching users
- Special characters in search

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/user_live_test.exs`
