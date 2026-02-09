# TC-018: Account Deletion with Wrong Password

## Linked User Story
- [US-005](../USER-STORY/US-005-account-deletion.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in

## Test Steps
1. Navigate to account settings
2. Click delete account option
3. Confirm deletion in dialog
4. Enter wrong password
5. Submit deletion

## Expected Results
- Deletion fails
- Error message: "Incorrect password"
- Account remains active
- User remains logged in

## Test Data
| Field | Value |
|-------|-------|
| password | WrongPassword123! |

## Edge Cases
- Empty password field

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
