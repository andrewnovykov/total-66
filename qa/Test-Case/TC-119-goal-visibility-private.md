# TC-119: Private Goal Visibility

## Linked User Story
- [US-104](../USER-STORY/US-104-goal-visibility.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Goal exists with visibility "private"
- Other user is logged in

## Test Steps
1. Log in as different user (not owner)
2. Attempt to access private goal by URL
3. Check if goal appears in any listing

## Expected Results
- Goal is not visible to others
- Direct URL access returns 404 or redirect
- Goal does not appear in discovery

## Test Data
| Field | Value |
|-------|-------|
| visibility | private |

## Edge Cases
- Owner views their private goal
- Admin access

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
