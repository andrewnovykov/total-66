# TC-543: Admin Removes Coach Role

## Linked User Story
- [US-511](../USER-STORY/US-511-coach-role-assignment.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Admin is logged in
- User has coach role

## Test Steps
1. Navigate to user management
2. Find coach user
3. Remove coach role
4. Save changes

## Expected Results
- User no longer has coach role
- User cannot access Coach Center
- Existing group goals preserved

## Test Data
| Field | Value |
|-------|-------|
| initial_role | coach |
| final_role | user |

## Edge Cases
- Coach with active group goals

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/user_live_test.exs`
