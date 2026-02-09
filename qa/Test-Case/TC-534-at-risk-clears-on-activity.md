# TC-534: At-Risk Clears on Activity

## Linked User Story
- [US-508](../USER-STORY/US-508-at-risk-indicators.md)

## Test Type
Integration

## Priority
Medium

## Preconditions
- Participant is at-risk

## Test Steps
1. Note participant is at-risk
2. Participant completes a step
3. Check at-risk status

## Expected Results
- At-risk indicator removed
- Participant back to normal status
- Dashboard updates

## Test Data
| Field | Value |
|-------|-------|
| initial_status | at_risk |
| final_status | normal |

## Edge Cases
- Activity just after midnight

## Automation Status
- [ ] Automated in: `test/heads_up/coach_center_test.exs`
