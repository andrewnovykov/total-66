# TC-011: Session Invalidation After Logout

## Linked User Story
- [US-003](../USER-STORY/US-003-user-logout.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User has just logged out

## Test Steps
1. After logout, attempt to access protected page directly
2. Use browser back button to return to protected page
3. Check session state

## Expected Results
- Protected pages redirect to login
- Session is fully invalidated
- Cannot use back button to access protected content

## Test Data
| Field | Value |
|-------|-------|
| protected_page | /my-goals |

## Edge Cases
- Multiple tabs open during logout

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/auth_live_test.exs`
