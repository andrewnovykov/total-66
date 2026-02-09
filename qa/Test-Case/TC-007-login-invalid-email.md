# TC-007: Login with Non-existent Email

## Linked User Story
- [US-002](../USER-STORY/US-002-user-login.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is not logged in
- Email does not exist in database

## Test Steps
1. Navigate to login page
2. Enter non-existent email: notfound@example.com
3. Enter password: AnyPassword123!
4. Click Login button

## Expected Results
- Login fails
- Generic error message: "Invalid email or password"
- User remains on login page
- No session created

## Test Data
| Field | Value |
|-------|-------|
| email | notfound@example.com |
| password | AnyPassword123! |

## Edge Cases
- Similar email with typo

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/auth_live_test.exs`
