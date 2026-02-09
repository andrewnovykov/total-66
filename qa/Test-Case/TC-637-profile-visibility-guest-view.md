# TC-637: Profile Visibility Guest View

## Linked User Story
- [US-606](../USER-STORY/US-606-profile-visibility.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Profiles with various visibility settings exist
- User is not logged in (guest)

## Test Steps
1. View public profile as guest
2. View private profile as guest
3. View friends-only profile as guest
4. Observe differences

## Expected Results
- Public profile fully visible
- Private profile shows minimal info
- Friends-only shows minimal info
- "Sign in to see more" prompts

## Test Data
| Field | Value |
|-------|-------|
| viewer | guest |
| profile_types | public, private, friends_only |

## Edge Cases
- All profiles same for guest (private/friends)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
