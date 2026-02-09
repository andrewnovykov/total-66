# TC-228: Cannot Send Duplicate Friend Request

## Linked User Story
- [US-206](../USER-STORY/US-206-friendships.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Friend request already pending

## Test Steps
1. Navigate to user with pending request
2. Attempt to send another request

## Expected Results
- Cannot send duplicate
- Button shows "Request Pending"
- API rejects duplicate

## Test Data
| Field | Value |
|-------|-------|
| existing_request | pending |

## Edge Cases
- Already friends

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/friend_live_test.exs`
