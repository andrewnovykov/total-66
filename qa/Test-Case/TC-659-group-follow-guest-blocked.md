# TC-659: Group Follow Guest Blocked

## Linked User Story
- [US-611](../USER-STORY/US-611-group-following.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is not logged in (guest)
- Group page accessible

## Test Steps
1. Navigate to group page as guest
2. Look for "Follow" button
3. Attempt to follow

## Expected Results
- Follow button shows "Sign in to follow"
- Clicking redirects to login
- No follow action performed
- API call also fails

## Test Data
| Field | Value |
|-------|-------|
| user_state | guest |
| expected_action | sign_in_prompt |

## Edge Cases
- Guest returns after login

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/group_live_test.exs`
