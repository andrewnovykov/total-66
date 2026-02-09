# TC-128: Goal Detail View as Guest

## Linked User Story
- [US-106](../USER-STORY/US-106-goal-detail-view.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is not logged in
- Goal is public

## Test Steps
1. Navigate to public goal detail page
2. Review available sections

## Expected Results
- Title and description visible
- Progress visible
- Steps visible (read-only)
- Posts visible
- No interaction buttons (like, subscribe)
- Prompt to log in for interactions

## Test Data
| Field | Value |
|-------|-------|
| user_role | guest |
| visibility | public |

## Edge Cases
- Guest tries to interact

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
