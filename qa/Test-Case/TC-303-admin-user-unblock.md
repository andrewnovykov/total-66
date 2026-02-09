# TC-303: Admin Unblock User

## Linked User Story
- [US-300](../USER-STORY/US-300-admin-user-management.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Admin user is logged in
- Target user is blocked

## Test Steps
1. Navigate to admin users page
2. Find blocked user
3. Click "Unblock" button
4. Confirm unblocking

## Expected Results
- User status changes to active
- User's content is visible again
- User can log in again

## Test Data
| Field | Value |
|-------|-------|
| target_user | blocked_user |
| initial_status | blocked |
| final_status | active |

## Edge Cases
- Unblock recently blocked user

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/user_live_test.exs`
