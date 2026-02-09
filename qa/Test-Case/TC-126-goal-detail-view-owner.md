# TC-126: Goal Detail View as Owner

## Linked User Story
- [US-106](../USER-STORY/US-106-goal-detail-view.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User owns the goal

## Test Steps
1. Navigate to owned goal detail page
2. Review all sections

## Expected Results
- Title and description visible
- Progress bar shows completion
- All steps listed with status
- Posts/feed visible
- Edit and delete buttons visible
- Status management options visible

## Test Data
| Field | Value |
|-------|-------|
| goal_owner | current_user |

## Edge Cases
- Goal with no steps
- Goal with no posts

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
