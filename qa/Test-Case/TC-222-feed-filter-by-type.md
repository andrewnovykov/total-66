# TC-222: Filter Feed by Post Type

## Linked User Story
- [US-205](../USER-STORY/US-205-user-feed.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- User is logged in
- Feed has posts of different types

## Test Steps
1. Navigate to feed
2. Select filter: "Milestones only"
3. Verify filtered results
4. Clear filter

## Expected Results
- Only milestone posts shown
- Filter is clearly indicated
- Clear filter restores all posts

## Test Data
| Field | Value |
|-------|-------|
| filter | milestone |

## Edge Cases
- Filter with no matching posts

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/feed_live_test.exs`
