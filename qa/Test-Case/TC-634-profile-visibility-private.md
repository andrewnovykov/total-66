# TC-634: Profile Visibility Private

## Linked User Story
- [US-606](../USER-STORY/US-606-profile-visibility.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User has private profile visibility setting

## Test Steps
1. Log in as different user (non-friend)
2. Navigate to private profile
3. Observe limited information shown
4. Compare to owner's view

## Expected Results
- Only basic info shown to non-friends
- Avatar and name visible
- Goals and activity hidden
- Stats may be limited

## Test Data
| Field | Value |
|-------|-------|
| profile_visibility | private |
| viewer | non_friend |
| visible_info | basic_only |

## Edge Cases
- Private profile owner views own profile

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
