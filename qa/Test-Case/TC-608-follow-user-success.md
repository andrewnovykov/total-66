# TC-608: Follow User Success

## Linked User Story
- [US-601](../USER-STORY/US-601-follow-user.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- Target user exists and is not followed

## Test Steps
1. Navigate to target user's profile
2. Click "Follow" button
3. Observe button state change
4. Check follower count on target profile

## Expected Results
- Follow action succeeds
- Button changes to "Following"
- Target's follower count increases by 1
- Success feedback shown

## Test Data
| Field | Value |
|-------|-------|
| follower_user | current_user |
| followed_user | other_user |

## Edge Cases
- Already following user

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
