# TC-630: Friend Remove Access Revoked

## Linked User Story
- [US-605](../USER-STORY/US-605-remove-friend.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User just removed as friend
- Former friend has friends-only content

## Test Steps
1. Remove friend relationship
2. Try to access former friend's friends-only goals
3. Observe access result

## Expected Results
- Access to friends-only content denied
- Cannot view friends-only goals
- Public content still visible
- Profile shows "Add Friend" again

## Test Data
| Field | Value |
|-------|-------|
| content_visibility | friends_only |
| access_result | denied |

## Edge Cases
- Content cached before removal

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
