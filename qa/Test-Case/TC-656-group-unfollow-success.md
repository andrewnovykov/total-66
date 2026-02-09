# TC-656: Unfollow Group Success

## Linked User Story
- [US-611](../USER-STORY/US-611-group-following.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User is following a group

## Test Steps
1. Navigate to followed group page
2. Click "Following" to unfollow
3. Observe button state change
4. Check group follower count

## Expected Results
- Unfollow action succeeds
- Button changes back to "Follow"
- Group follower count decreases
- Group content no longer in feed

## Test Data
| Field | Value |
|-------|-------|
| action | unfollow_group |
| initial_state | following |

## Edge Cases
- Not currently following

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/group_live_test.exs`
