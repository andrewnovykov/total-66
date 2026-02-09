# TC-441: Non-Admin Cannot Create Template

## Linked User Story
- [US-410](../USER-STORY/US-410-admin-create-challenge-template.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- Regular user is logged in

## Test Steps
1. Attempt to access admin challenge page
2. Attempt API template creation

## Expected Results
- Admin page returns 403 or redirect
- API creation returns 403
- No template created

## Test Data
| Field | Value |
|-------|-------|
| user_role | user |

## Edge Cases
- Coach role (if exists)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/challenge_live_test.exs`
