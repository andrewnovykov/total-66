# TC-535: Group Completion Percentage

## Linked User Story
- [US-509](../USER-STORY/US-509-group-goal-completion.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Active group goal with participants

## Test Steps
1. Navigate to group goal
2. View overall completion statistics
3. Check percentage calculation

## Expected Results
- Overall percentage displayed
- Calculated from participant averages
- Updated in real-time

## Test Data
| Field | Value |
|-------|-------|
| participant_1 | 50% |
| participant_2 | 100% |
| overall | 75% |

## Edge Cases
- All participants at 0%

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/group_goal_live_test.exs`
