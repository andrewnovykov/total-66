# TC-541: Visibility Applies to Outsiders

## Linked User Story
- [US-510](../USER-STORY/US-510-participant-visibility.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Participant has private goal instance
- Outside user is logged in

## Test Steps
1. Log in as outsider (not coach, not friend)
2. Attempt to view participant's goal
3. Observe access result

## Expected Results
- Access denied or hidden
- Cannot view goal details
- Visibility enforced

## Test Data
| Field | Value |
|-------|-------|
| participant_visibility | private |
| viewer_role | outsider |

## Edge Cases
- Friend of participant

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
