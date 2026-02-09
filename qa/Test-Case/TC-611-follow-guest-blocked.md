# TC-611: Follow as Guest Blocked

## Linked User Story
- [US-601](../USER-STORY/US-601-follow-user.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is not logged in (guest)
- Target user profile exists

## Test Steps
1. Navigate to user profile as guest
2. Look for Follow button
3. Click the follow action area

## Expected Results
- Button shows "Sign in to follow"
- Clicking redirects to login page
- No follow action performed

## Test Data
| Field | Value |
|-------|-------|
| user_state | guest |
| target_profile | other_user |

## Edge Cases
- Guest returns to profile after login

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
