# TC-545: Removed Coach No Access

## Linked User Story
- [US-511](../USER-STORY/US-511-coach-role-assignment.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User just lost coach role
- User is logged in

## Test Steps
1. Refresh navigation
2. Look for Coach Center
3. Attempt direct URL access

## Expected Results
- Coach Center not in nav
- Direct URL returns 403/redirect
- Regular user features still work

## Test Data
| Field | Value |
|-------|-------|
| previous_role | coach |
| current_role | user |

## Edge Cases
- Role removed during active session

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach_center_live_test.exs`
