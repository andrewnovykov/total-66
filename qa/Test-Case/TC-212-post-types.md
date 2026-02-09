# TC-212: Different Post Types

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
1. Create post type "update"
2. Create post type "milestone"
3. Create post type "achievement"
4. Create post type "challenge"
5. Create post type "motivation"
6. Verify each displays correctly

## Expected Results
- Each type has distinct visual styling
- Type icon/badge displayed
- All types appear in feed

## Test Data
| Field | Value |
|-------|-------|
| types | update, milestone, achievement, challenge, motivation |

## Edge Cases
- Change post type after creation

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_post_live_test.exs`
