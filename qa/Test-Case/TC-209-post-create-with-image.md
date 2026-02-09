# TC-209: Create Goal Post with Image

## Linked User Story
- [US-202](../USER-STORY/US-202-goal-posts.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User owns the goal

## Test Steps
1. Navigate to owned goal detail
2. Click "New Post" button
3. Enter content
4. Upload image
5. Submit post

## Expected Results
- Post is created with image
- Image is displayed in post
- Image is properly resized/compressed

## Test Data
| Field | Value |
|-------|-------|
| content | Check out my progress! |
| image | progress_photo.jpg |

## Edge Cases
- Invalid image type
- Image too large

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_post_live_test.exs`
