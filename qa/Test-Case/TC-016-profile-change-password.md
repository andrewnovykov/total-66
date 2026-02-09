# TC-016: Change Password

## Linked User Story
- [US-004](../USER-STORY/US-004-profile-management.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in

## Test Steps
1. Navigate to password change section
2. Enter current password
3. Enter new password
4. Confirm new password
5. Save changes

## Expected Results
- Password is updated
- Success message shown
- User can log in with new password

## Test Data
| Field | Value |
|-------|-------|
| current_password | OldPass123! |
| new_password | NewPass456! |
| confirm_password | NewPass456! |

## Edge Cases
- Wrong current password
- New password same as old
- Password mismatch

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
