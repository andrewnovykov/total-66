# TC-017: Successful Account Deletion

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
4. Enter password to confirm
5. Submit deletion

## Expected Results
- Account is deleted/anonymized
- User is logged out
- User is redirected to home
- Cannot log in with old credentials

## Test Data
| Field | Value |
|-------|-------|
| password | SecurePass123! |

## Edge Cases
- User with active goals
- User with subscriptions

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
