# TC-653: Follow from Top Setters

## Linked User Story
- [US-610](../USER-STORY/US-610-top-goal-setters.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- User is logged in
- Top setters section visible

## Test Steps
1. View top goal setters section
2. Click "Follow" on a top setter
3. Verify follow succeeds
4. Check button state changes

## Expected Results
- Can follow directly from section
- Button changes to "Following"
- Follower count updates
- User stays in top setters (follows don't affect ranking)

## Test Data
| Field | Value |
|-------|-------|
| action | follow |
| context | top_setters |

## Edge Cases
- Already following a top setter

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
