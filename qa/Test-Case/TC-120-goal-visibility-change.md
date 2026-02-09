# TC-120: Change Goal Visibility

## Linked User Story
- [US-104](../USER-STORY/US-104-goal-visibility.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User owns a public goal

## Test Steps
1. Navigate to owned goal edit page
2. Change visibility from "public" to "private"
3. Save changes
4. Verify visibility enforcement

## Expected Results
- Visibility is updated
- Goal no longer appears in public discovery
- Existing subscribers lose access

## Test Data
| Field | Value |
|-------|-------|
| old_visibility | public |
| new_visibility | private |

## Edge Cases
- Subscriptions when visibility changes

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
