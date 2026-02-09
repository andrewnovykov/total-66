# TC-009: Session Persistence After Login

## Linked User Story
- [US-002](../USER-STORY/US-002-user-login.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in

## Test Steps
1. After successful login, note session state
2. Refresh the page
3. Navigate to different pages
4. Check session state

## Expected Results
- Session persists after page refresh
- User remains logged in during navigation
- Authenticated menu items still visible

## Test Data
| Field | Value |
|-------|-------|
| email | test@example.com |

## Edge Cases
- Browser tab closed and reopened
- Session timeout

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/auth_live_test.exs`
