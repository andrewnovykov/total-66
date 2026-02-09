# TC-216: Successfully Create Comment

## Linked User Story
- [US-204](../USER-STORY/US-204-post-comments.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- Post is on a visible goal

## Test Steps
1. Navigate to post
2. Enter comment text: "Great progress!"
3. Submit comment

## Expected Results
- Comment is created
- Comment appears below post
- Author and timestamp shown
- Comment count increases

## Test Data
| Field | Value |
|-------|-------|
| comment_text | Great progress! |

## Edge Cases
- Empty comment (should fail)
- Very long comment

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_post_live_test.exs`
