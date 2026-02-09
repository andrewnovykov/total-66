# TC-004: Registration with Password Mismatch

## Linked User Story
- [US-001](../USER-STORY/US-001-user-registration.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is not logged in

## Test Steps
1. Navigate to registration page
2. Enter valid email: test@example.com
3. Enter valid username: testuser
4. Enter password: SecurePass123!
5. Enter different password confirmation: DifferentPass456!
6. Click Register button

## Expected Results
- Registration fails
- Error message: "Passwords do not match"
- User remains on registration page
- No account created

## Test Data
| Field | Value |
|-------|-------|
| email | test@example.com |
| username | testuser |
| password | SecurePass123! |
| password_confirmation | DifferentPass456! |

## Edge Cases
- Extra whitespace in password

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/auth_live_test.exs`
