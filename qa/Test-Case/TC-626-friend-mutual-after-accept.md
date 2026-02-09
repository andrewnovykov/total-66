# TC-626: Mutual Friendship After Accept

## Linked User Story
- [US-604](../USER-STORY/US-604-friend-request-respond.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Friend request just accepted

## Test Steps
1. Check accepter's friends list
2. Check sender's friends list
3. Verify both show each other as friends
4. Check friends-only content access

## Expected Results
- Both users appear in each other's friends list
- Friendship is mutual (bidirectional)
- Both can access friends-only content
- Profile shows "Friends" status on both sides

## Test Data
| Field | Value |
|-------|-------|
| user_a | request_sender |
| user_b | request_accepter |
| relationship | mutual_friends |

## Edge Cases
- One-sided view before refresh

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
