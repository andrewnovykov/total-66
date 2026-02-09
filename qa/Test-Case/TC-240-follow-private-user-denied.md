# TC-240: Follow Private User Denied

## Linked User Story
- [US-209](../USER-STORY/US-209-follow-privacy.md)

## Test Type
Integration / API

## Priority
High

## Preconditions
- User A is logged in
- User B has privacy set to "private"

## Test Steps
1. Navigate to User B's profile
2. Attempt to click "Follow" button
3. Verify follow is denied
4. OR via API: POST /api/users/:user_b_id/follow
5. Verify 403 response with error message

## Expected Results
- Follow button may be hidden or disabled
- If clicked, error message "Cannot follow private user"
- API returns 403 Forbidden
- No follow relationship is created

## Test Data
| Field | Value |
|-------|-------|
| follower | user_a@example.com |
| private_user | private@example.com |
| privacy_setting | private |

## Edge Cases
- User changes privacy while follow request in flight
- Admin users may have different rules

## Automation Status
- [ ] Automated in: `test/heads_up_web/controllers/api/user_api_test.exs`
