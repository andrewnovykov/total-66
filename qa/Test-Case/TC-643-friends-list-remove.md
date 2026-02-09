# TC-643: Remove Friend from List

## Linked User Story
- [US-608](../USER-STORY/US-608-friends-list.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Viewing friends list

## Test Steps
1. Open friends list
2. Click "Remove Friend" on a friend
3. Confirm removal
4. Observe friend removed from list

## Expected Results
- Confirmation dialog appears
- Friend removed on confirm
- List updates immediately
- Friend count decreases

## Test Data
| Field | Value |
|-------|-------|
| action | remove_friend |
| context | friends_list |

## Edge Cases
- Last friend removed

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
