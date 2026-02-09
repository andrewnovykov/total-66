# TC-223: Feed Empty State

## Linked User Story
- [US-205](../USER-STORY/US-205-user-feed.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User has no subscriptions

## Test Steps
1. Navigate to feed
2. Observe empty state

## Expected Results
- Empty state message displayed
- Suggestion to discover goals
- Link to goals discovery page

## Test Data
| Field | Value |
|-------|-------|
| subscriptions | 0 |

## Edge Cases
- New user first login

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/feed_live_test.exs`
