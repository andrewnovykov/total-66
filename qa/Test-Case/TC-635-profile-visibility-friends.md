# TC-635: Profile Visibility Friends Only

## Linked User Story
- [US-606](../USER-STORY/US-606-profile-visibility.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User has friends-only profile visibility
- Viewer is accepted friend

## Test Steps
1. Log in as friend
2. Navigate to friends-only profile
3. Observe full profile visible
4. Log in as non-friend
5. Navigate to same profile
6. Observe limited view

## Expected Results
- Friends see full profile
- Non-friends see limited info
- Friend can see friends-only goals
- Non-friend cannot see friends-only content

## Test Data
| Field | Value |
|-------|-------|
| profile_visibility | friends_only |
| friend_access | full |
| non_friend_access | limited |

## Edge Cases
- Pending friend request

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
