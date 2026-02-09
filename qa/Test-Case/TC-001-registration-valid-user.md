# TC-001: Valid User Registration

## Linked User Story
- [US-001](../USER-STORY/US-001-user-registration.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- User is not logged in
- Email and username are not taken

## Test Steps
1. Navigate to registration page
2. Enter valid email: test@example.com
3. Enter valid username: testuser
4. Enter password: SecurePass123!
5. Enter password confirmation: SecurePass123!
6. Click Register button

## Expected Results
- User account is created
- User is automatically logged in
- User is redirected to home page
- Navigation shows authenticated menu items

## Test Data
| Field | Value |
|-------|-------|
| email | test@example.com |
| username | testuser |
| password | SecurePass123! |

## Edge Cases
- Unicode characters in username
- Very long email address

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/auth_live_test.exs`
