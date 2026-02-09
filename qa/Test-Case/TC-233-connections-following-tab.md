# TC-233: Connections Following Tab

## Linked User Story
- [US-208](../USER-STORY/US-208-connections-manager.md)

## Test Type
LiveView / Integration

## Priority
High

## Preconditions
- User is logged in
- User is following at least 2 other users

## Test Steps
1. Navigate to `/connections`
2. Click on "Following" tab (or verify it's active by default)
3. Verify the list shows users being followed
4. Verify each user card shows: avatar, name, username, bio
5. Click "View Profile" on a user
6. Return to connections page
7. Click "Unfollow" on a user
8. Verify the user is removed from the list
9. Verify Following count decreases by 1

## Expected Results
- Following tab displays all followed users
- User cards show complete information
- View Profile navigates to `/people/:username`
- Unfollow removes user from list immediately
- Stats count updates in real-time

## Test Data
| Field | Value |
|-------|-------|
| current_user | user@example.com |
| followed_user_1 | jane@example.com |
| followed_user_2 | mike@example.com |

## Edge Cases
- Empty state: "You're not following anyone yet" with CTA to browse people
- Unfollow shows confirmation toast

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
