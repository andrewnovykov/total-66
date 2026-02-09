# TC-646: Friends Count Display

## Linked User Story
- [US-608](../USER-STORY/US-608-friends-list.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User has known number of friends

## Test Steps
1. Navigate to own profile
2. Observe friends count in stats
3. Add a friend
4. Verify count updates
5. Remove a friend
6. Verify count updates

## Expected Results
- Friends count displayed on profile
- Count updates in real-time
- Count is accurate
- Shown to profile visitors too

## Test Data
| Field | Value |
|-------|-------|
| initial_friends | 5 |
| after_add | 6 |
| after_remove | 5 |

## Edge Cases
- Zero friends

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
