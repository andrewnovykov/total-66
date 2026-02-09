# TC-002: Registration with Duplicate Email

## Linked User Story
- [US-001](../USER-STORY/US-001-user-registration.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is not logged in
- Email already exists in database

## Test Steps
1. Navigate to registration page
2. Enter existing email: existing@example.com
3. Enter valid username: newuser
4. Enter password: SecurePass123!
5. Enter password confirmation: SecurePass123!
6. Click Register button

## Expected Results
- Registration fails
- Error message: "Email has already been taken"
- User remains on registration page
- No account created

## Test Data
| Field | Value |
|-------|-------|
| email | existing@example.com |
| username | newuser |
| password | SecurePass123! |

## Edge Cases
- Same email with different case (case insensitive)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/auth_live_test.exs`
