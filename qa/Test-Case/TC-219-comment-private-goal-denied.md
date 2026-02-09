# TC-219: Cannot Comment on Private Goal Post

## Linked User Story
- [US-204](../USER-STORY/US-204-post-comments.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Goal is private
- User is not owner

## Test Steps
1. Attempt to access private goal post
2. Attempt to comment via API

## Expected Results
- Cannot access private goal
- Cannot comment on inaccessible content
- API returns error

## Test Data
| Field | Value |
|-------|-------|
| goal_visibility | private |

## Edge Cases
- URL manipulation

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_post_live_test.exs`
