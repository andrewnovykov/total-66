# TC-235: Connections Friends Tab

## Linked User Story
- [US-208](../USER-STORY/US-208-connections-manager.md)

## Test Type
LiveView / Integration

## Priority
High

## Preconditions
- User is logged in
- User has at least 1 accepted friend

## Test Steps
1. Navigate to `/connections`
2. Click on "Friends" tab
3. Verify the list shows mutual friends
4. Verify each friend card shows: avatar, name, username, bio
5. Click "View Profile" on a friend
6. Return to connections page
7. Click "Remove Friend" (or equivalent action) on a friend
8. Confirm the removal in dialog
9. Verify the friend is removed from the list
10. Verify Friends count decreases by 1

## Expected Results
- Friends tab displays all accepted friendships
- User cards show complete information
- View Profile navigates to `/people/:username`
- Remove Friend requires confirmation
- Friendship is removed for both users
- Stats count updates in real-time

## Test Data
| Field | Value |
|-------|-------|
| current_user | user@example.com |
| friend | jane@example.com |

## Edge Cases
- Empty state: "No friends yet" with "Send friend requests to build your network"
- CTA button to find friends

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
