# TC-620: Duplicate Friend Request Blocked

## Linked User Story
- [US-603](../USER-STORY/US-603-friend-request-send.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- Pending friend request already sent to target

## Test Steps
1. Navigate to target user's profile
2. Observe "Request Sent" button state
3. Try to send another request (if possible)

## Expected Results
- Cannot send duplicate request
- Button shows "Request Sent" (not clickable for new request)
- Error shown if trying via API

## Test Data
| Field | Value |
|-------|-------|
| existing_request | pending |
| action | blocked |

## Edge Cases
- Request sent but not yet processed

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
