# TC-655: Follow Group Success

## Linked User Story
- [US-611](../USER-STORY/US-611-group-following.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Group exists and is not followed

## Test Steps
1. Navigate to group page
2. Click "Follow" button
3. Observe button state change
4. Check group follower count

## Expected Results
- Follow action succeeds
- Button changes to "Following"
- Group follower count increases
- Success feedback shown

## Test Data
| Field | Value |
|-------|-------|
| action | follow_group |
| initial_state | not_following |

## Edge Cases
- Already following group

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/group_live_test.exs`
