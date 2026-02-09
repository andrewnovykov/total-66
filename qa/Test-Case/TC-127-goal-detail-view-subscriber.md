# TC-127: Goal Detail View as Subscriber

## Linked User Story
- [US-106](../USER-STORY/US-106-goal-detail-view.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User has subscribed to the goal

## Test Steps
1. Navigate to subscribed goal detail page
2. Review available sections

## Expected Results
- Title and description visible
- Progress bar shows completion
- Steps visible (read-only)
- Posts/feed visible
- Like and comment options available
- No edit/delete buttons
- Unsubscribe option visible

## Test Data
| Field | Value |
|-------|-------|
| user_role | subscriber |

## Edge Cases
- Private goal subscription (shouldn't exist)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
