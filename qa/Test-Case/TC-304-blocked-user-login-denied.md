# TC-304: Blocked User Cannot Login

## Linked User Story
- [US-300](../USER-STORY/US-300-admin-user-management.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- User account is blocked
- User is not logged in

## Test Steps
1. Navigate to login page
2. Enter blocked user credentials
3. Attempt login

## Expected Results
- Login is denied
- Error message: "Account is blocked"
- No session created

## Test Data
| Field | Value |
|-------|-------|
| user_status | blocked |

## Edge Cases
- Session exists before block

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/auth_live_test.exs`
