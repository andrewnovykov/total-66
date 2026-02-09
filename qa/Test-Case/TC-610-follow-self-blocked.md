# TC-610: Follow Self Blocked

## Linked User Story
- [US-601](../USER-STORY/US-601-follow-user.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in

## Test Steps
1. Navigate to own profile
2. Look for Follow button
3. Verify Follow button is not present

## Expected Results
- Follow button not shown on own profile
- Only "Edit Profile" action available
- No way to follow yourself

## Test Data
| Field | Value |
|-------|-------|
| viewer | current_user |
| profile | current_user |

## Edge Cases
- Direct API call to follow self should fail

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
