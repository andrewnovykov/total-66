# TC-242: Self-Follow Denied

## Linked User Story
- [US-209](../USER-STORY/US-209-follow-privacy.md)

## Test Type
Integration / API

## Priority
High

## Preconditions
- User is logged in

## Test Steps
1. Navigate to own profile
2. Verify "Follow" button is not visible (or is disabled)
3. OR via API: POST /api/users/:own_id/follow
4. Verify 403 response with error message

## Expected Results
- Cannot follow yourself
- Follow button hidden or disabled on own profile
- API returns 403 with "You cannot follow yourself"
- No self-follow relationship created

## Test Data
| Field | Value |
|-------|-------|
| user | user@example.com |

## Edge Cases
- Direct API call attempted
- URL manipulation to own profile

## Automation Status
- [ ] Automated in: `test/heads_up_web/controllers/api/user_api_test.exs`
