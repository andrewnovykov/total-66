# TC-633: Profile Visibility Public

## Linked User Story
- [US-606](../USER-STORY/US-606-profile-visibility.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User has public profile visibility setting

## Test Steps
1. Log in as different user (non-friend)
2. Navigate to public profile
3. Observe visible information
4. Log out and view as guest

## Expected Results
- Full profile visible to logged-in users
- Full profile visible to guests
- All public goals visible
- Stats and activity visible

## Test Data
| Field | Value |
|-------|-------|
| profile_visibility | public |
| viewer_types | guest, logged_in, friend |

## Edge Cases
- Profile with no content

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
