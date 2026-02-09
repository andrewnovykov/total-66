# TC-627: Friend Count Updates on Accept

## Linked User Story
- [US-604](../USER-STORY/US-604-friend-request-respond.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Friend request pending
- Both users have known friend counts

## Test Steps
1. Note both users' friend counts
2. Accept friend request
3. Check both users' friend counts immediately
4. Refresh and verify counts persist

## Expected Results
- Both counts increase by 1
- Updates happen immediately
- Counts persist after refresh
- Profile stats reflect new count

## Test Data
| Field | Value |
|-------|-------|
| sender_initial_friends | 5 |
| sender_after_friends | 6 |
| accepter_initial_friends | 3 |
| accepter_after_friends | 4 |

## Edge Cases
- Concurrent friend acceptances

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
