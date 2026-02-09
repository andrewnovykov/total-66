# TC-013: Edit Profile Username

## Linked User Story
- [US-004](../USER-STORY/US-004-profile-management.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- New username is not taken

## Test Steps
1. Navigate to profile edit page
2. Enter new username: newusername
3. Save changes

## Expected Results
- Username is updated
- Success message shown
- New username reflected in profile

## Test Data
| Field | Value |
|-------|-------|
| old_username | testuser |
| new_username | newusername |

## Edge Cases
- Username already taken
- Invalid characters in username

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
