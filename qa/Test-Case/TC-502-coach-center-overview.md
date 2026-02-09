# TC-502: Coach Center Overview Display

## Linked User Story
- [US-500](../USER-STORY/US-500-coach-center-access.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Coach is logged in
- Coach has group goals

## Test Steps
1. Navigate to Coach Center
2. View overview section
3. Check displayed information

## Expected Results
- Group goals list displayed
- Summary statistics shown
- Quick action buttons available
- Recent activity visible

## Test Data
| Field | Value |
|-------|-------|
| group_goals | 3 |
| total_participants | 15 |

## Edge Cases
- No group goals (empty state)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach_center_live_test.exs`
