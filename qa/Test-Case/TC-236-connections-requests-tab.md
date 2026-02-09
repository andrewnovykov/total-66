# TC-236: Connections Requests Tab

## Linked User Story
- [US-208](../USER-STORY/US-208-connections-manager.md)

## Test Type
LiveView / Integration

## Priority
High

## Preconditions
- User is logged in
- User has at least 1 incoming friend request
- User has at least 1 sent friend request pending

## Test Steps
### Incoming Requests
1. Navigate to `/connections`
2. Click on "Requests" tab
3. Verify "Incoming Friend Requests" section shows pending requests
4. Click "Accept" on an incoming request
5. Verify the user moves to Friends tab
6. Verify Friends count increases by 1
7. Return to another incoming request
8. Click "Decline"
9. Verify the request is removed

### Sent Requests
10. Scroll to "Sent Friend Requests" section
11. Verify sent requests show "Pending approval" status
12. Click "Cancel Request" on a sent request
13. Verify the request is removed from the list

## Expected Results
- Incoming requests display with Accept/Decline buttons
- Accepting creates mutual friendship
- Declining removes the request
- Sent requests show pending status
- Cancel removes the sent request
- Counts update appropriately

## Test Data
| Field | Value |
|-------|-------|
| current_user | user@example.com |
| incoming_requester | john@example.com |
| sent_to_user | private@example.com |

## Edge Cases
- Empty incoming: "No pending friend requests" / "Friend requests will appear here"
- Empty sent: No sent requests section or empty message
- Request count in stats reflects pending incoming only

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
