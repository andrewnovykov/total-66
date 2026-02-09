# TC-631: Friend Remove Confirmation Dialog

## Linked User Story
- [US-605](../USER-STORY/US-605-remove-friend.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User has at least one friend

## Test Steps
1. Click "Remove Friend" button
2. Observe confirmation dialog appears
3. Click "Cancel" and verify no change
4. Click "Remove Friend" again
5. Click "Confirm" and verify removal

## Expected Results
- Confirmation dialog shown before removal
- Cancel closes dialog without action
- Confirm performs removal
- Accidental removal prevented

## Test Data
| Field | Value |
|-------|-------|
| dialog_type | confirmation |
| actions | cancel, confirm |

## Edge Cases
- Dialog dismissed by clicking outside

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
