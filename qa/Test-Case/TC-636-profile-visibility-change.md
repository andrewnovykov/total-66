# TC-636: Profile Visibility Change

## Linked User Story
- [US-606](../USER-STORY/US-606-profile-visibility.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User has existing visibility setting

## Test Steps
1. Navigate to profile settings
2. Change visibility from public to private
3. Save changes
4. Verify changes apply immediately
5. Have another user view profile

## Expected Results
- Visibility setting saved
- Changes apply immediately
- New visibility enforced for viewers
- No refresh needed for enforcement

## Test Data
| Field | Value |
|-------|-------|
| initial_visibility | public |
| new_visibility | private |

## Edge Cases
- Change while being viewed

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/settings_live_test.exs`
