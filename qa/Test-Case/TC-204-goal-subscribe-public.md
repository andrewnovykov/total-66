# TC-204: Subscribe to Public Goal

## Linked User Story
- [US-201](../USER-STORY/US-201-goal-subscriptions.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- Goal is public
- User is not subscribed

## Test Steps
1. Navigate to public goal detail
2. Click Subscribe button
3. Navigate to user's feed

## Expected Results
- Subscription is created
- Subscribe button changes to Unsubscribe
- Goal posts appear in user's feed
- Subscription count increases

## Test Data
| Field | Value |
|-------|-------|
| goal_visibility | public |

## Edge Cases
- Subscribe to goal with no posts

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
