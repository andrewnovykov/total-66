# TC-613: Unfollow User Success

## Linked User Story
- [US-602](../USER-STORY/US-602-unfollow-user.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User is following target user

## Test Steps
1. Navigate to followed user's profile
2. Click "Following" button to unfollow
3. Observe button state change
4. Check follower count on target profile

## Expected Results
- Unfollow action succeeds
- Button changes back to "Follow"
- Target's follower count decreases by 1
- Success feedback shown

## Test Data
| Field | Value |
|-------|-------|
| action | unfollow |
| initial_state | following |

## Edge Cases
- Not currently following user

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
