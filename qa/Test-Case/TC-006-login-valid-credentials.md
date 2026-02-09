# TC-006: Login with Valid Credentials

## Linked User Story
- [US-002](../USER-STORY/US-002-user-login.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- User account exists
- User is not logged in

## Test Steps
1. Navigate to login page
2. Enter valid email: test@example.com
3. Enter valid password: SecurePass123!
4. Click Login button

## Expected Results
- User is logged in
- User is redirected to home page
- Navigation shows authenticated menu items
- Session is established

## Test Data
| Field | Value |
|-------|-------|
| email | test@example.com |
| password | SecurePass123! |

## Edge Cases
- Login immediately after registration

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/auth_live_test.exs`
