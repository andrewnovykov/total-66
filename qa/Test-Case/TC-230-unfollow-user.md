# TC-230: Unfollow User

## Linked User Story
- [US-207](../USER-STORY/US-207-user-following.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Currently following target user

## Test Steps
1. Navigate to followed user's profile
2. Click "Unfollow" button
3. Verify status change

## Expected Results
- No longer following
- Button changes to "Follow"
- Follower count decreases

## Test Data
| Field | Value |
|-------|-------|
| initial_status | following |
| final_status | not_following |

## Edge Cases
- Unfollow immediately after following

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/follow_live_test.exs`
