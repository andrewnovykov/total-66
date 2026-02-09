# TC-658: Group Activity in Feed

## Linked User Story
- [US-611](../USER-STORY/US-611-group-following.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User follows a group
- Group has recent activity

## Test Steps
1. Follow a group
2. Navigate to feed
3. Observe group activity items
4. Verify items attributed to group

## Expected Results
- Group activity appears in feed
- Shows new goals created in group
- Shows popular goals from group
- Items indicate "In group [X]"

## Test Data
| Field | Value |
|-------|-------|
| followed_group | test_group |
| feed_items | group_goals, group_updates |

## Edge Cases
- Group with no activity

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/feed_live_test.exs`
