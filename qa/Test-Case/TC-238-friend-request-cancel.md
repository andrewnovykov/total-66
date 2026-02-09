# TC-238: Cancel Friend Request

## Linked User Story
- [US-206](../USER-STORY/US-206-friendships.md)
- [US-208](../USER-STORY/US-208-connections-manager.md)

## Test Type
Integration

## Priority
Medium

## Preconditions
- User A is logged in
- User A has sent a friend request to User B
- Request is still pending

## Test Steps
1. Navigate to `/connections`
2. Click on "Requests" tab
3. Locate the sent request to User B in "Sent Friend Requests" section
4. Verify "Pending approval" status is shown
5. Click "Cancel Request" button
6. Verify the request is removed from the list
7. Verify User B no longer sees the incoming request

## Expected Results
- Cancel button removes the pending request
- Request disappears from sender's sent list
- Request disappears from receiver's incoming list
- No friendship is created
- Toast message confirms cancellation

## Test Data
| Field | Value |
|-------|-------|
| sender | user_a@example.com |
| receiver | user_b@example.com |

## Edge Cases
- Cannot cancel already accepted request
- Cannot cancel already declined request
- Cancelling non-existent request returns error

## Automation Status
- [ ] Automated in: `test/heads_up/accounts_test.exs`
