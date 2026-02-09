# TC-104: Goal Creation with Different Visibility Options

## Linked User Story
- [US-100](../USER-STORY/US-100-goal-creation.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in

## Test Steps
1. Create goal with visibility "public"
2. Verify public goal is visible to others
3. Create goal with visibility "friends_only"
4. Verify goal visible only to friends
5. Create goal with visibility "private"
6. Verify goal visible only to owner

## Expected Results
- Each visibility option works correctly
- Public goals appear in discovery
- Private goals hidden from others

## Test Data
| Field | Value |
|-------|-------|
| visibility_options | public, friends_only, private |

## Edge Cases
- Changing visibility after creation

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
