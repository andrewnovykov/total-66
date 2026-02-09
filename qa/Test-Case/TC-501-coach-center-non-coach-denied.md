# TC-501: Non-Coach Cannot Access Coach Center

## Linked User Story
- [US-500](../USER-STORY/US-500-coach-center-access.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- User has regular user role (not coach)
- User is logged in

## Test Steps
1. Check navigation for Coach Center
2. Attempt to access /coach-center directly
3. Observe response

## Expected Results
- Coach Center not in navigation
- Direct URL access returns 403 or redirect
- Access denied message shown

## Test Data
| Field | Value |
|-------|-------|
| user_role | user |

## Edge Cases
- Admin access (may have full access)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach_center_live_test.exs`
