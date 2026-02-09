# TC-544: Coach Role Grants Access

## Linked User Story
- [US-511](../USER-STORY/US-511-coach-role-assignment.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User just received coach role
- User is logged in

## Test Steps
1. Refresh navigation
2. Look for Coach Center
3. Access Coach Center

## Expected Results
- Coach Center appears in nav
- Can access all coaching features
- Regular user features still work

## Test Data
| Field | Value |
|-------|-------|
| user_role | coach |

## Edge Cases
- After role assignment mid-session

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach_center_live_test.exs`
