# TC-210: Edit Own Post

## Linked User Story
- [US-202](../USER-STORY/US-202-goal-posts.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User created the post

## Test Steps
1. Navigate to post
2. Click Edit button
3. Update content
4. Save changes

## Expected Results
- Post content is updated
- "Edited" indicator shown
- Edit timestamp updated

## Test Data
| Field | Value |
|-------|-------|
| new_content | Updated progress update! |

## Edge Cases
- Edit immediately after posting
- Remove all content (should fail)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_post_live_test.exs`
