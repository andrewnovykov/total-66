# TC-629: Friend Remove Count Update

## Linked User Story
- [US-605](../USER-STORY/US-605-remove-friend.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User has friends with known count
- Friend removal just performed

## Test Steps
1. Note both users' friend counts before
2. Remove friend
3. Check both counts immediately
4. Refresh and verify persistence

## Expected Results
- Both counts decrease by 1
- Updates happen immediately
- Counts persist after refresh

## Test Data
| Field | Value |
|-------|-------|
| remover_before | 5 |
| remover_after | 4 |
| removed_before | 10 |
| removed_after | 9 |

## Edge Cases
- Friend count already 0

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
