# TC-524: Dashboard Participant List

## Linked User Story
- [US-506](../USER-STORY/US-506-coach-dashboard.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Coach is logged in
- Active group goal with participants

## Test Steps
1. Navigate to group goal
2. View participant list
3. Check information displayed

## Expected Results
- All participants listed
- Name, status, progress shown
- Last activity visible
- Can click for details

## Test Data
| Field | Value |
|-------|-------|
| participants | 10 |

## Edge Cases
- Participant removed themselves

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach_center_live_test.exs`
