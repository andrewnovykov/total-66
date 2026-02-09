# TC-521: Participant Creates Post

## Linked User Story
- [US-505](../USER-STORY/US-505-participant-goal-instance.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Participant has goal instance

## Test Steps
1. Navigate to goal instance
2. Click "New Post"
3. Enter update content
4. Submit post

## Expected Results
- Post is created
- Post appears in goal feed
- Coach can see post

## Test Data
| Field | Value |
|-------|-------|
| content | Made progress today! |
| post_type | update |

## Edge Cases
- Post with image

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_post_live_test.exs`
