# TC-618: Friend Request Button States

## Linked User Story
- [US-603](../USER-STORY/US-603-friend-request-send.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Various friendship states exist

## Test Steps
1. View profile of stranger (no relationship)
2. Observe "Add Friend" button
3. View profile of user with pending sent request
4. Observe "Request Sent" button
5. View profile of user with pending received request
6. Observe "Accept/Decline" buttons
7. View profile of existing friend
8. Observe "Friends" state

## Expected Results
- Stranger: "Add Friend"
- Pending sent: "Request Sent"
- Pending received: "Accept" / "Decline"
- Friend: "Friends" with unfriend option

## Test Data
| Field | Value |
|-------|-------|
| states | add_friend, request_sent, accept_decline, friends |

## Edge Cases
- State changes while viewing

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
