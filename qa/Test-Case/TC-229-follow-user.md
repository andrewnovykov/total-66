# TC-229: Follow User

## Linked User Story
- [US-207](../USER-STORY/US-207-user-following.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Target user exists
- Not already following

## Test Steps
1. Navigate to target user's profile
2. Click "Follow" button
3. Verify follow status

## Expected Results
- Now following user
- Button changes to "Unfollow"
- Target's follower count increases

## Test Data
| Field | Value |
|-------|-------|
| target_user | other_user |

## Edge Cases
- Follow self (should fail)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/follow_live_test.exs`
