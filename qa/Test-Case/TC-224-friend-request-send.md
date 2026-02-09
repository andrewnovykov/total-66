# TC-224: Send Friend Request

## Linked User Story
- [US-206](../USER-STORY/US-206-friendships.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Target user exists
- Not already friends

## Test Steps
1. Navigate to target user's profile
2. Click "Add Friend" button
3. Observe status change

## Expected Results
- Friend request is sent
- Button changes to "Request Pending"
- Target user sees pending request

## Test Data
| Field | Value |
|-------|-------|
| target_user | other_user |
| status | pending |

## Edge Cases
- Send to user with pending request

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/friend_live_test.exs`
