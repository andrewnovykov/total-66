# TC-206: Cannot Subscribe to Private Goal

## Linked User Story
- [US-201](../USER-STORY/US-201-goal-subscriptions.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- Goal is private
- User is not the owner

## Test Steps
1. Attempt to access private goal
2. Attempt to subscribe via API

## Expected Results
- Cannot view private goal
- Subscribe option not available
- API subscription returns error

## Test Data
| Field | Value |
|-------|-------|
| goal_visibility | private |

## Edge Cases
- URL manipulation

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
