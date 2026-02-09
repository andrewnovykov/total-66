# TC-651: Top Goal Setters Display

## Linked User Story
- [US-610](../USER-STORY/US-610-top-goal-setters.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- Users with varying activity levels exist
- People page is accessible

## Test Steps
1. Navigate to /people
2. Observe "Top Goal Setters" section
3. Verify user cards displayed
4. Check stats and badges shown

## Expected Results
- Section visible to all (guests and users)
- Shows users with high consistency
- Displays avatar, name, level, goals count
- Ordered by activity/consistency

## Test Data
| Field | Value |
|-------|-------|
| section | top_goal_setters |
| ordering | consistency_score |

## Edge Cases
- No users meet top setter criteria

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
