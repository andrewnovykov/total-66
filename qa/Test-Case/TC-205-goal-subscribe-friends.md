# TC-205: Subscribe to Friends-Only Goal

## Linked User Story
- [US-201](../USER-STORY/US-201-goal-subscriptions.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User is friends with goal owner
- Goal is friends-only

## Test Steps
1. Navigate to friend's friends-only goal
2. Click Subscribe button
3. Verify subscription

## Expected Results
- Subscription is created
- Goal posts appear in feed
- Can view goal content

## Test Data
| Field | Value |
|-------|-------|
| goal_visibility | friends_only |
| friendship_status | accepted |

## Edge Cases
- Friend removed after subscription

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
