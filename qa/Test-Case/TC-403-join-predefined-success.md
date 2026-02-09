# TC-403: Successfully Join Predefined Challenge

## Linked User Story
- [US-401](../USER-STORY/US-401-join-predefined-challenge.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- User is logged in
- User has fewer than 3 active items
- Predefined challenge exists

## Test Steps
1. Navigate to challenges page
2. Click "Join" on a predefined challenge
3. Confirm joining
4. View challenge detail

## Expected Results
- Challenge is joined
- Challenge appears in My Challenges
- Active item count increases
- Progress tracking begins at 0%

## Test Data
| Field | Value |
|-------|-------|
| challenge_type | predefined |
| initial_active_items | 1 |

## Edge Cases
- Join same challenge twice

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
