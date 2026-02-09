# TC-208: Successfully Create Goal Post

## Linked User Story
- [US-202](../USER-STORY/US-202-goal-posts.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User owns the goal

## Test Steps
1. Navigate to owned goal detail
2. Click "New Post" button
3. Enter content: "Made great progress today!"
4. Select type: "update"
5. Submit post

## Expected Results
- Post is created
- Post appears in goal feed
- Timestamp shows "just now"
- Subscribers receive update in feed

## Test Data
| Field | Value |
|-------|-------|
| content | Made great progress today! |
| post_type | update |

## Edge Cases
- Empty content (should fail)
- Very long content

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_post_live_test.exs`
