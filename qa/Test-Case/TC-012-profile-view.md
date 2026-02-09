# TC-012: View Own Profile

## Linked User Story
- [US-004](../USER-STORY/US-004-profile-management.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in

## Test Steps
1. Navigate to profile page
2. View profile information

## Expected Results
- Profile page displays user information
- Username is visible
- Bio/about section is visible
- Profile photo is displayed
- Edit options are available

## Test Data
| Field | Value |
|-------|-------|
| username | testuser |
| bio | Test bio |

## Edge Cases
- Profile with no optional fields set

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
