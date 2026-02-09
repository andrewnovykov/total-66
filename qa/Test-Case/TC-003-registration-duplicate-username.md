# TC-003: Registration with Duplicate Username

## Linked User Story
- [US-001](../USER-STORY/US-001-user-registration.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is not logged in
- Username already exists in database

## Test Steps
1. Navigate to registration page
2. Enter valid email: new@example.com
3. Enter existing username: existinguser
4. Enter password: SecurePass123!
5. Enter password confirmation: SecurePass123!
6. Click Register button

## Expected Results
- Registration fails
- Error message: "Username has already been taken"
- User remains on registration page
- No account created

## Test Data
| Field | Value |
|-------|-------|
| email | new@example.com |
| username | existinguser |
| password | SecurePass123! |

## Edge Cases
- Same username with different case

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/auth_live_test.exs`
