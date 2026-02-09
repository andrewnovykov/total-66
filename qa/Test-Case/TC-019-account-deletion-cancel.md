# TC-019: Cancel Account Deletion

## Linked User Story
- [US-005](../USER-STORY/US-005-account-deletion.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in

## Test Steps
1. Navigate to account settings
2. Click delete account option
3. Click cancel in confirmation dialog

## Expected Results
- Deletion is cancelled
- Account remains active
- User returns to settings page
- No data changed

## Test Data
| Field | Value |
|-------|-------|
| user | Active user |

## Edge Cases
- Click outside modal to close

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
