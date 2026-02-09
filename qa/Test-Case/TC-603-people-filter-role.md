# TC-603: People Filter by Role

## Linked User Story
- [US-600](../USER-STORY/US-600-people-directory.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Users with different roles exist (user, coach)
- User is on /people page

## Test Steps
1. Select "All" role filter
2. Observe results show all users
3. Select "Coach" role filter
4. Observe results show only coaches

## Expected Results
- All filter shows everyone
- Coach filter shows only users with coach role
- Role badge visible on coach cards

## Test Data
| Field | Value |
|-------|-------|
| role_filter | all, coach |

## Edge Cases
- No coaches in system

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
