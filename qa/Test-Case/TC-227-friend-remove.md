# TC-227: Remove Friend

## Linked User Story
- [US-206](../USER-STORY/US-206-friendships.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Has existing friendship

## Test Steps
1. Navigate to friend's profile
2. Click "Remove Friend" button
3. Confirm removal

## Expected Results
- Friendship is removed
- Both users no longer friends
- Friends-only content access revoked

## Test Data
| Field | Value |
|-------|-------|
| initial_status | friends |
| final_status | not_friends |

## Edge Cases
- Remove friend with shared subscriptions

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/friend_live_test.exs`
