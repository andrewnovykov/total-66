# TC-617: Send Friend Request Success

## Linked User Story
- [US-603](../USER-STORY/US-603-friend-request-send.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- Target user exists and is not a friend

## Test Steps
1. Navigate to target user's profile
2. Click "Add Friend" button
3. Observe button state change
4. Verify request sent notification

## Expected Results
- Friend request sent successfully
- Button changes to "Request Sent"
- Target receives notification
- Request recorded in database

## Test Data
| Field | Value |
|-------|-------|
| sender | current_user |
| recipient | other_user |
| request_status | pending |

## Edge Cases
- User with disabled notifications

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
