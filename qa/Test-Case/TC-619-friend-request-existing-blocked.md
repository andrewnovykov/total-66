# TC-619: Friend Request to Existing Friend Blocked

## Linked User Story
- [US-603](../USER-STORY/US-603-friend-request-send.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User is already friends with target

## Test Steps
1. Navigate to friend's profile
2. Look for "Add Friend" button
3. Verify button is not present

## Expected Results
- No "Add Friend" button shown
- Shows "Friends" status instead
- Only unfriend option available

## Test Data
| Field | Value |
|-------|-------|
| relationship | friends |
| expected_button | Friends |

## Edge Cases
- Direct API call should also fail

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
