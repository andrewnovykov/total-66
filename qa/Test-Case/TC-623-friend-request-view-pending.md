# TC-623: View Pending Friend Requests

## Linked User Story
- [US-604](../USER-STORY/US-604-friend-request-respond.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User has pending friend requests

## Test Steps
1. Navigate to friends/connections page
2. Find pending requests section
3. Observe request list with sender info
4. Verify Accept/Decline buttons present

## Expected Results
- Pending requests section visible
- Shows sender's avatar, name, and info
- Accept and Decline buttons on each request
- Request count badge shown

## Test Data
| Field | Value |
|-------|-------|
| pending_count | 3 |
| section | pending_requests |

## Edge Cases
- No pending requests

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
