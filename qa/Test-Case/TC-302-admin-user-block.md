# TC-302: Admin Block User

## Linked User Story
- [US-300](../USER-STORY/US-300-admin-user-management.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- Admin user is logged in
- Target user is active

## Test Steps
1. Navigate to admin users page
2. Find target user
3. Click "Block" button
4. Confirm blocking

## Expected Results
- User status changes to blocked
- User's content is hidden
- Blocked user cannot log in

## Test Data
| Field | Value |
|-------|-------|
| target_user | regular_user |
| initial_status | active |
| final_status | blocked |

## Edge Cases
- Block admin user
- Block user with active sessions

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/user_live_test.exs`
