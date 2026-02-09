# TC-005: Registration with Missing Required Fields

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
2. Leave email field empty
3. Leave username field empty
4. Leave password field empty
5. Click Register button

## Expected Results
- Registration fails
- Error messages for each required field
- User remains on registration page
- No account created

## Test Data
| Field | Value |
|-------|-------|
| email | (empty) |
| username | (empty) |
| password | (empty) |

## Edge Cases
- Only some fields empty
- Whitespace-only values

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/auth_live_test.exs`
