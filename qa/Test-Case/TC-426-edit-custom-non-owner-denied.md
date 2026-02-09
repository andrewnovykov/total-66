# TC-426: Non-Owner Cannot Edit Custom Challenge

## Linked User Story
- [US-406](../USER-STORY/US-406-edit-custom-challenge.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User does NOT own the custom challenge

## Test Steps
1. Navigate to another user's custom challenge
2. Attempt to find Edit button
3. Attempt API edit

## Expected Results
- Edit button not visible
- API edit returns 403
- Challenge unchanged

## Test Data
| Field | Value |
|-------|-------|
| challenge_owner | other_user |
| current_user | test_user |

## Edge Cases
- Admin editing custom challenge

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
