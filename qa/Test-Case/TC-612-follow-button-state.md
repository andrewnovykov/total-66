# TC-612: Follow Button State Management

## Linked User Story
- [US-601](../USER-STORY/US-601-follow-user.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Various relationship states with different users

## Test Steps
1. View profile of user not followed
2. Observe "Follow" button state
3. View profile of user being followed
4. Observe "Following" button state
5. Verify button is clickable in both states

## Expected Results
- Not followed: shows "Follow" button
- Following: shows "Following" button
- Button states are visually distinct
- Hover states indicate action

## Test Data
| Field | Value |
|-------|-------|
| not_followed_state | Follow |
| followed_state | Following |

## Edge Cases
- Button state during loading

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
