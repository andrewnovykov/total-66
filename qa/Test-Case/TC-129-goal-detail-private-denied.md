# TC-129: Private Goal Access Denied

## Linked User Story
- [US-106](../USER-STORY/US-106-goal-detail-view.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Goal is private
- User is logged in but not owner

## Test Steps
1. Attempt to access private goal by URL
2. Observe response

## Expected Results
- Access is denied
- 404 or redirect response
- Cannot see any goal details

## Test Data
| Field | Value |
|-------|-------|
| visibility | private |
| user_role | non_owner |

## Edge Cases
- URL guessing attack

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
