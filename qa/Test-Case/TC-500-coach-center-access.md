# TC-500: Coach Can Access Coach Center

## Linked User Story
- [US-500](../USER-STORY/US-500-coach-center-access.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- User has coach role
- User is logged in

## Test Steps
1. Look for "Coach Center" in navigation
2. Click "Coach Center"
3. Observe page loads

## Expected Results
- Coach Center link is visible in navigation
- Page loads successfully
- Dashboard content is displayed

## Test Data
| Field | Value |
|-------|-------|
| user_role | coach |

## Edge Cases
- Coach with no group goals yet

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach_center_live_test.exs`
