# TC-644: Friends Pending Requests Tab

## Linked User Story
- [US-608](../USER-STORY/US-608-friends-list.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User has pending friend requests

## Test Steps
1. Navigate to friends/connections page
2. Click "Pending" tab or section
3. View incoming requests
4. View sent requests (if shown)

## Expected Results
- Pending tab accessible
- Shows incoming requests with Accept/Decline
- May show sent requests with status
- Badge shows pending count

## Test Data
| Field | Value |
|-------|-------|
| incoming_requests | 3 |
| sent_requests | 2 |

## Edge Cases
- No pending requests

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
