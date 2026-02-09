# TC-430: Mark Challenge as Completed

## Linked User Story
- [US-408](../USER-STORY/US-408-challenge-status-management.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User has active challenge
- All tasks completed (or manual completion allowed)

## Test Steps
1. Navigate to challenge
2. Click "Complete Challenge" button
3. Confirm completion

## Expected Results
- Challenge status changes to "completed"
- Moves to challenge history
- Active item slot freed
- Success celebration shown

## Test Data
| Field | Value |
|-------|-------|
| initial_status | active |
| final_status | completed |

## Edge Cases
- Complete with incomplete tasks

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
