# TC-622: Friend Request as Guest Blocked

## Linked User Story
- [US-603](../USER-STORY/US-603-friend-request-send.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is not logged in (guest)

## Test Steps
1. Navigate to user profile as guest
2. Look for "Add Friend" button
3. Observe available actions

## Expected Results
- No "Add Friend" button for guests
- Prompt to sign in for social actions
- API call should fail for guests

## Test Data
| Field | Value |
|-------|-------|
| user_state | guest |
| expected_action | sign_in_prompt |

## Edge Cases
- Guest clicks sign in then sends request

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
