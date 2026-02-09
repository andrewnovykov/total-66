# TC-624: Accept Friend Request

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
2. Click "Accept" on a request
3. Observe request removal from pending
4. Check friends list for new friend

## Expected Results
- Request accepted successfully
- Request removed from pending list
- New friend appears in friends list
- Both users' friend counts increase

## Test Data
| Field | Value |
|-------|-------|
| request_sender | other_user |
| action | accept |

## Edge Cases
- Request cancelled before accept

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
