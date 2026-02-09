# TC-402: Filter Challenges by Duration

## Linked User Story
- [US-400](../USER-STORY/US-400-browse-challenges.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Challenges of different durations exist

## Test Steps
1. Navigate to challenges page
2. Select "30-day" filter
3. Observe filtered results
4. Clear filter

## Expected Results
- Only 30-day challenges shown
- Filter state is indicated
- Clearing restores all challenges

## Test Data
| Field | Value |
|-------|-------|
| filter | 30-day |

## Edge Cases
- Filter with no matches

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
