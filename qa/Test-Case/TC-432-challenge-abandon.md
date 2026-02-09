# TC-432: Abandon Challenge Early

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
2. Click "Quit Challenge" button
3. Confirm abandonment

## Expected Results
- Challenge is removed
- Active item slot freed
- May appear in history as "abandoned"

## Test Data
| Field | Value |
|-------|-------|
| initial_status | active |
| final_status | abandoned |

## Edge Cases
- Abandon on first day

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
