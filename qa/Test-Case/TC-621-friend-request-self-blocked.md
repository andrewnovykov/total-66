# TC-621: Friend Request to Self Blocked

## Linked User Story
- [US-603](../USER-STORY/US-603-friend-request-send.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in

## Test Steps
1. Navigate to own profile
2. Look for "Add Friend" button
3. Verify button is not present

## Expected Results
- No "Add Friend" button on own profile
- Only "Edit Profile" available
- API call to self should fail

## Test Data
| Field | Value |
|-------|-------|
| viewer | current_user |
| profile | current_user |

## Edge Cases
- Direct API attempt

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
