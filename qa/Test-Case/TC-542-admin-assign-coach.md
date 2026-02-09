# TC-542: Admin Assigns Coach Role

## Linked User Story
- [US-511](../USER-STORY/US-511-coach-role-assignment.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Admin is logged in
- User exists without coach role

## Test Steps
1. Navigate to user management
2. Find user
3. Assign coach role
4. Save changes

## Expected Results
- User now has coach role
- User can access Coach Center
- Change reflected immediately

## Test Data
| Field | Value |
|-------|-------|
| initial_role | user |
| final_role | coach |

## Edge Cases
- User already coach

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/user_live_test.exs`
