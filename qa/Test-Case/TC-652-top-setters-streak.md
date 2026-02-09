# TC-652: Top Setters Streak Indicator

## Linked User Story
- [US-610](../USER-STORY/US-610-top-goal-setters.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- Users with active streaks exist

## Test Steps
1. View top goal setters section
2. Observe streak indicators on cards
3. Verify streak count accuracy
4. Check streak badge styling

## Expected Results
- Streak indicator visible on cards
- Shows consecutive days active
- Visual badge for long streaks
- Accurate streak counts

## Test Data
| Field | Value |
|-------|-------|
| user_streak | 7 days |
| streak_badge | visible |

## Edge Cases
- User with broken streak

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
