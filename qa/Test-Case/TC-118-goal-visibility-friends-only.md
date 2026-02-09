# TC-118: Friends-Only Goal Visibility

## Linked User Story
- [US-104](../USER-STORY/US-104-goal-visibility.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Goal exists with visibility "friends_only"
- Friend user is logged in
- Non-friend user is logged in

## Test Steps
1. Log in as friend of goal owner
2. Navigate to goal - should be visible
3. Log in as non-friend
4. Attempt to view goal

## Expected Results
- Friend can see full goal detail
- Non-friend cannot see goal content
- Goal appears in friend's feed if subscribed

## Test Data
| Field | Value |
|-------|-------|
| visibility | friends_only |

## Edge Cases
- Friend request pending

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
