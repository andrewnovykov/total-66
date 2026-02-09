# TC-431: Mark Challenge as Failed

## Linked User Story
- [US-408](../USER-STORY/US-408-challenge-status-management.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User has active challenge

## Test Steps
1. Navigate to challenge
2. Click "Fail Challenge" button
3. Enter reason (if required)
4. Confirm failure

## Expected Results
- Challenge status changes to "failed"
- Moves to challenge history
- Active item slot freed
- Reason recorded

## Test Data
| Field | Value |
|-------|-------|
| initial_status | active |
| final_status | failed |
| reason | Lost motivation |

## Edge Cases
- Fail without reason (if required)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
