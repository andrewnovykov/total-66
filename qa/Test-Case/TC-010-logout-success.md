# TC-010: Successful Logout

## Linked User Story
- [US-003](../USER-STORY/US-003-user-logout.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in

## Test Steps
1. Click logout button in navigation
2. Confirm logout action

## Expected Results
- User session ends
- User is redirected to home or login page
- Navigation shows guest menu items
- Protected pages no longer accessible

## Test Data
| Field | Value |
|-------|-------|
| user | Logged in user |

## Edge Cases
- Logout from different pages

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/auth_live_test.exs`
