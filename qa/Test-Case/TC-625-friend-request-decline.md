# TC-625: Decline Friend Request

## Linked User Story
- [US-604](../USER-STORY/US-604-friend-request-respond.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User has pending friend request

## Test Steps
1. Navigate to pending requests
2. Click "Decline" on a request
3. Observe request removal from pending
4. Verify no new friend added

## Expected Results
- Request declined successfully
- Request removed from pending list
- No new friend in friends list
- Sender not notified of decline

## Test Data
| Field | Value |
|-------|-------|
| request_sender | other_user |
| action | decline |

## Edge Cases
- Sender can send new request after decline

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
