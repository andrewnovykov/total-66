# TC-657: Group Follower Count Update

## Linked User Story
- [US-611](../USER-STORY/US-611-group-following.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Group with known follower count

## Test Steps
1. Note group's follower count
2. Follow group
3. Verify count increases immediately
4. Unfollow group
5. Verify count decreases

## Expected Results
- Count updates in real-time
- Follow increases count by 1
- Unfollow decreases count by 1
- Count persists after refresh

## Test Data
| Field | Value |
|-------|-------|
| initial_count | 25 |
| after_follow | 26 |
| after_unfollow | 25 |

## Edge Cases
- Multiple users following simultaneously

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/group_live_test.exs`
