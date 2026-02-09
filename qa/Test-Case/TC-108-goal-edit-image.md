# TC-108: Edit Goal Image

## Linked User Story
- [US-101](../USER-STORY/US-101-goal-editing.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User owns the goal

## Test Steps
1. Navigate to goal edit page
2. Click change image button
3. Upload new image
4. Preview image
5. Save changes

## Expected Results
- Image is updated
- Preview shows new image
- New image displayed on goal detail

## Test Data
| Field | Value |
|-------|-------|
| image_file | new_goal_image.jpg |

## Edge Cases
- Remove existing image
- Invalid file type

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
