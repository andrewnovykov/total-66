# TC-401: Challenges List Display

## Linked User Story
- [US-400](../USER-STORY/US-400-browse-challenges.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- Predefined challenges exist

## Test Steps
1. Navigate to challenges page
2. View list of challenges
3. Check each challenge card

## Expected Results
- All predefined challenges displayed
- Each shows title, description, duration
- Join buttons visible
- Grouped by category

## Test Data
| Field | Value |
|-------|-------|
| challenge_count | 5+ |
| categories | 30-day, 90-day, custom |

## Edge Cases
- No challenges available

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
