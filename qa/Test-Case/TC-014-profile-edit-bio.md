# TC-014: Edit Profile Bio

## Linked User Story
- [US-004](../USER-STORY/US-004-profile-management.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- User is logged in

## Test Steps
1. Navigate to profile edit page
2. Enter new bio text
3. Save changes

## Expected Results
- Bio is updated
- Success message shown
- New bio reflected in profile

## Test Data
| Field | Value |
|-------|-------|
| bio | This is my new bio text |

## Edge Cases
- Very long bio text
- Bio with special characters

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
