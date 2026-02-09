# TC-616: Re-follow After Unfollow

## Linked User Story
- [US-602](../USER-STORY/US-602-unfollow-user.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User recently unfollowed target user

## Test Steps
1. View target user's profile (not following)
2. Click "Follow" button
3. Verify follow succeeds
4. Check content appears in feed

## Expected Results
- Can re-follow without restrictions
- Button changes to "Following"
- Follower count increases
- Content returns to feed

## Test Data
| Field | Value |
|-------|-------|
| previous_state | unfollowed |
| new_state | following |

## Edge Cases
- Rapid unfollow/follow cycles

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
