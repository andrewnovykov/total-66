# TC-218: Guest Cannot Comment

## Linked User Story
- [US-204](../USER-STORY/US-204-post-comments.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is not logged in
- Post is public

## Test Steps
1. Navigate to post as guest
2. Attempt to find comment form

## Expected Results
- Comment form is hidden
- Prompt to log in shown
- API comment attempt fails

## Test Data
| Field | Value |
|-------|-------|
| user_role | guest |

## Edge Cases
- Direct API attempt

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_post_live_test.exs`
