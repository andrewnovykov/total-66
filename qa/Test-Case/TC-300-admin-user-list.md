# TC-300: Admin User List

## Linked User Story
- [US-300](../USER-STORY/US-300-admin-user-management.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Admin user is logged in
- Multiple users exist

## Test Steps
1. Navigate to admin dashboard
2. Click "Users" section
3. View user list

## Expected Results
- All users are listed
- User info visible (name, email, status)
- Pagination works for many users
- Action buttons visible

## Test Data
| Field | Value |
|-------|-------|
| user_role | admin |
| total_users | 100+ |

## Edge Cases
- No users (impossible)
- Very large user list

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/user_live_test.exs`
