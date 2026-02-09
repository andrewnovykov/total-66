# TC-604: People Filter by Friendship Status

## Linked User Story
- [US-600](../USER-STORY/US-600-people-directory.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User has friends and pending requests
- User is on /people page

## Test Steps
1. Select "Not friends" filter
2. Observe results exclude friends
3. Select "Friends" filter
4. Observe results show only friends
5. Select "Pending requests" filter
6. Observe results show pending requests

## Expected Results
- Not friends shows non-friend users
- Friends shows only accepted friends
- Pending shows sent/received requests

## Test Data
| Field | Value |
|-------|-------|
| friendship_filters | not_friends, friends, pending |

## Edge Cases
- User has no friends
- User has no pending requests
- Guest cannot see friendship filter

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
