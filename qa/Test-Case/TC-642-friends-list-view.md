# TC-642: View Friends List

## Linked User Story
- [US-608](../USER-STORY/US-608-friends-list.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User has friends

## Test Steps
1. Navigate to profile or connections page
2. Click on friends count/link
3. Observe friends list
4. Verify friend information displayed

## Expected Results
- Friends list opens
- Shows user cards for each friend
- Displays avatar, name, bio
- Shows "Remove Friend" action

## Test Data
| Field | Value |
|-------|-------|
| friends_count | 8 |
| list_type | friends |

## Edge Cases
- User has no friends

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
