# TC-234: Connections Followers Tab

## Linked User Story
- [US-208](../USER-STORY/US-208-connections-manager.md)

## Test Type
LiveView / Integration

## Priority
High

## Preconditions
- User is logged in
- At least 1 other user is following the current user

## Test Steps
1. Navigate to `/connections`
2. Click on "Followers" tab
3. Verify the list shows users who are followers
4. Verify each user card shows: avatar, name, username, bio
5. Click "View Profile" on a follower
6. Return to connections page
7. Click "Remove" on a follower
8. Verify the follower is removed from the list
9. Verify Followers count decreases by 1

## Expected Results
- Followers tab displays all followers
- User cards show complete information
- View Profile navigates to `/people/:username`
- Remove action removes follower from list
- Removed user can no longer follow the current user
- Stats count updates in real-time

## Test Data
| Field | Value |
|-------|-------|
| current_user | user@example.com |
| follower | jane@example.com |

## Edge Cases
- Empty state: "No followers yet"
- Remove shows confirmation dialog

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
