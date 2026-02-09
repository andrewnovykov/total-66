# TC-525: Dashboard Progress Display

## Linked User Story
- [US-506](../USER-STORY/US-506-coach-dashboard.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Coach is logged in
- Participants have various progress levels

## Test Steps
1. Navigate to group goal
2. View participant progress
3. Check progress bars/percentages

## Expected Results
- Progress percentage shown per participant
- Visual progress bars
- Average group progress visible

## Test Data
| Field | Value |
|-------|-------|
| participant_1_progress | 50% |
| participant_2_progress | 25% |
| average_progress | 37.5% |

## Edge Cases
- All at 0%
- All at 100%

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach_center_live_test.exs`
