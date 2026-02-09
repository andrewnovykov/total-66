# TC-518: Start with Participant at Active Limit

## Linked User Story
- [US-504](../USER-STORY/US-504-start-group-goal.md)

## Test Type
Integration

## Priority
High

## Preconditions
- Participant has 3 active items already

## Test Steps
1. Add participant at limit
2. Start group goal
3. Check participant's goal instance

## Expected Results
- Group goal starts
- Participant's instance may be "blocked" or queued
- Warning shown to coach
- Other participants unaffected

## Test Data
| Field | Value |
|-------|-------|
| participant_active_items | 3 |

## Edge Cases
- All participants at limit

## Automation Status
- [ ] Automated in: `test/heads_up/coach_center_test.exs`
