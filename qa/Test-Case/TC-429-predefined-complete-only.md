# TC-429: Predefined Challenge - Complete Actions Only

## Linked User Story
- [US-407](../USER-STORY/US-407-predefined-challenge-readonly.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User has joined predefined challenge

## Test Steps
1. Navigate to predefined challenge
2. View available actions
3. Complete a step
4. Verify no edit actions

## Expected Results
- Can complete steps
- Can view progress
- Cannot edit any content
- Cannot add/remove steps

## Test Data
| Field | Value |
|-------|-------|
| available_actions | complete_step |
| unavailable_actions | edit, delete, add |

## Edge Cases
- All steps completed

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
