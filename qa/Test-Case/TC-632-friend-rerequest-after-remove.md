# TC-632: Re-request Friend After Remove

## Linked User Story
- [US-605](../USER-STORY/US-605-remove-friend.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User recently removed a friend

## Test Steps
1. Navigate to former friend's profile
2. Click "Add Friend" button
3. Verify request sent successfully
4. Check button state changes

## Expected Results
- Can send new friend request
- Button changes to "Request Sent"
- Request appears in recipient's pending
- No restrictions from previous friendship

## Test Data
| Field | Value |
|-------|-------|
| previous_state | friends |
| current_state | request_pending |

## Edge Cases
- Rapid remove/rerequest cycles

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
