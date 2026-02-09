# TC-523: Dashboard Shows Group Goal List

## Linked User Story
- [US-506](../USER-STORY/US-506-coach-dashboard.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Coach is logged in
- Multiple group goals exist

## Test Steps
1. Navigate to Coach Center
2. View dashboard
3. Check group goals list

## Expected Results
- All group goals listed
- Each shows title, status, participant count
- Can drill down to details

## Test Data
| Field | Value |
|-------|-------|
| group_goals | 3 |

## Edge Cases
- No group goals (empty state)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach_center_live_test.exs`
