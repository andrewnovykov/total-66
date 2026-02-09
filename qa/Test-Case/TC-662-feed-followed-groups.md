# TC-662: Feed Shows Followed Groups Updates

## Linked User Story
- [US-612](../USER-STORY/US-612-social-feed.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User follows groups with activity

## Test Steps
1. Follow a group
2. New goal created in group
3. Navigate to feed
4. Verify group activity appears

## Expected Results
- Group activity in feed
- Shows "In group [X] new goal [Title]"
- Popular goals from group shown
- Group context visible

## Test Data
| Field | Value |
|-------|-------|
| followed_groups | 2 |
| feed_content | group_activity |

## Edge Cases
- Group with no recent activity

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/feed_live_test.exs`
