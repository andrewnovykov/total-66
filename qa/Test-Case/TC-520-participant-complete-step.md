# TC-520: Participant Completes Step

## Linked User Story
- [US-505](../USER-STORY/US-505-participant-goal-instance.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Participant has goal instance
- Steps are incomplete

## Test Steps
1. Navigate to goal instance
2. Find step to complete
3. Click complete checkbox
4. Observe progress update

## Expected Results
- Step marked as complete
- Progress percentage increases
- Coach can see update

## Test Data
| Field | Value |
|-------|-------|
| step | Step 1 |
| completed | true |

## Edge Cases
- Complete out of order

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
