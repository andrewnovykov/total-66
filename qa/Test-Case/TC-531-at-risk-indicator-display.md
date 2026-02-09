# TC-531: At-Risk Indicator Display

## Linked User Story
- [US-508](../USER-STORY/US-508-at-risk-indicators.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Participant inactive for threshold period

## Test Steps
1. Navigate to group goal dashboard
2. View participant with inactivity
3. Check indicator

## Expected Results
- At-risk indicator visible (red/yellow)
- Clearly distinguishable from normal
- Count of days inactive shown

## Test Data
| Field | Value |
|-------|-------|
| inactive_days | 7 |
| threshold | 5 |

## Edge Cases
- Just crossed threshold

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach_center_live_test.exs`
