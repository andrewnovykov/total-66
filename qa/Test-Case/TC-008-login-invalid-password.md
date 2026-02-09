# TC-008: Login with Wrong Password

## Linked User Story
- [US-002](../USER-STORY/US-002-user-login.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User account exists
- User is not logged in

## Test Steps
1. Navigate to login page
2. Enter valid email: test@example.com
3. Enter wrong password: WrongPassword123!
4. Click Login button

## Expected Results
- Login fails
- Generic error message: "Invalid email or password"
- User remains on login page
- No session created

## Test Data
| Field | Value |
|-------|-------|
| email | test@example.com |
| password | WrongPassword123! |

## Edge Cases
- Password with extra whitespace

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/auth_live_test.exs`
