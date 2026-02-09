# TC-532: At-Risk Calculation Logic

## Linked User Story
- [US-508](../USER-STORY/US-508-at-risk-indicators.md)

## Test Type
Unit

## Priority
Medium

## Preconditions
- Defined threshold (e.g., 5 days)

## Test Steps
1. Participant active yesterday - not at risk
2. Participant active 4 days ago - not at risk
3. Participant active 5 days ago - at risk
4. Participant active 10 days ago - at risk

## Expected Results
- Calculation based on last activity
- Threshold correctly applied
- Edge cases handled

## Test Data
| Field | Value |
|-------|-------|
| threshold | 5 days |

## Edge Cases
- No activity ever
- Activity today

## Automation Status
- [ ] Automated in: `test/heads_up/coach_center_test.exs`
