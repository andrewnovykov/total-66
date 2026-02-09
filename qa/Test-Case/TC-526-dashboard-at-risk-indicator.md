# TC-526: Dashboard At-Risk Indicator

## Linked User Story
- [US-506](../USER-STORY/US-506-coach-dashboard.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Coach is logged in
- Participant has no recent activity

## Test Steps
1. Navigate to group goal
2. View participant list
3. Check for at-risk indicator

## Expected Results
- At-risk icon visible for inactive participant
- Red/yellow warning color
- Hover shows inactivity period

## Test Data
| Field | Value |
|-------|-------|
| inactive_days | 7 |
| indicator | at_risk |

## Edge Cases
- Just became at-risk

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach_center_live_test.exs`
