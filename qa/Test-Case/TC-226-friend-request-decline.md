# TC-226: Decline Friend Request

## Linked User Story
- [US-206](../USER-STORY/US-206-friendships.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Has pending friend request

## Test Steps
1. Navigate to friend requests
2. Click Decline on pending request
3. Verify status

## Expected Results
- Request is declined
- Request removed from list
- Requester can send again later

## Test Data
| Field | Value |
|-------|-------|
| request_status | pending |
| final_status | declined |

## Edge Cases
- Decline then re-request

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/friend_live_test.exs`
