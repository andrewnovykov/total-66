# TC-207: Unsubscribe from Goal

## Linked User Story
- [US-201](../USER-STORY/US-201-goal-subscriptions.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User is subscribed to the goal

## Test Steps
1. Navigate to subscribed goal
2. Click Unsubscribe button
3. Check user's feed

## Expected Results
- Subscription is removed
- Button changes to Subscribe
- Goal posts no longer in feed
- Subscription count decreases

## Test Data
| Field | Value |
|-------|-------|
| subscribed | true |

## Edge Cases
- Unsubscribe while viewing feed

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
