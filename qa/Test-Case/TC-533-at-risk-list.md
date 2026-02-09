# TC-533: At-Risk Participants List

## Linked User Story
- [US-508](../USER-STORY/US-508-at-risk-indicators.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Multiple at-risk participants exist

## Test Steps
1. Navigate to Coach Center
2. Find at-risk summary/list
3. View all at-risk participants

## Expected Results
- Dedicated at-risk section/filter
- All at-risk listed together
- Quick access to details
- Count shown

## Test Data
| Field | Value |
|-------|-------|
| at_risk_count | 3 |

## Edge Cases
- No at-risk participants

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach_center_live_test.exs`
