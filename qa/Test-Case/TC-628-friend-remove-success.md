# TC-628: Remove Friend Success

## Linked User Story
- [US-605](../USER-STORY/US-605-remove-friend.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User has at least one friend

## Test Steps
1. Navigate to friends list or friend's profile
2. Click "Remove Friend" or unfriend option
3. Confirm removal in dialog
4. Observe friend removed

## Expected Results
- Friend removed successfully
- Friend removed from friends list
- Both users' friend counts decrease
- Relationship no longer mutual

## Test Data
| Field | Value |
|-------|-------|
| action | remove_friend |
| initial_state | friends |

## Edge Cases
- Friend already removed

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
