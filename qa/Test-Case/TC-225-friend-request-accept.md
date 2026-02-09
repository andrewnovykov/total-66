# TC-225: Accept Friend Request

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
2. Click Accept on pending request
3. Verify friendship

## Expected Results
- Friendship is created
- Both users are now friends
- Can see friends-only content

## Test Data
| Field | Value |
|-------|-------|
| request_status | pending |
| final_status | accepted |

## Edge Cases
- Accept after long delay

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/friend_live_test.exs`
