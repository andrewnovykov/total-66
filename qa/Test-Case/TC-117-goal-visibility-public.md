# TC-117: Public Goal Visibility

## Linked User Story
- [US-104](../USER-STORY/US-104-goal-visibility.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Goal exists with visibility "public"
- Other user is logged in

## Test Steps
1. Log in as different user
2. Navigate to goals discovery page
3. Search for public goal
4. View goal detail

## Expected Results
- Goal appears in discovery
- Goal detail is fully visible
- All posts are visible
- Like/subscribe options available

## Test Data
| Field | Value |
|-------|-------|
| visibility | public |

## Edge Cases
- Guest viewing public goal

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
