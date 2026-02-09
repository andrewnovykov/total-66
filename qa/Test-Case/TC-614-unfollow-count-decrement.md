# TC-614: Unfollow Count Decrement

## Linked User Story
- [US-602](../USER-STORY/US-602-unfollow-user.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in and following target
- Target user has known follower count

## Test Steps
1. Note target user's follower count
2. Click "Following" to unfollow
3. Observe count immediately after click
4. Refresh and verify count

## Expected Results
- Count decreases immediately
- Count persists after refresh
- Own following count also decreases

## Test Data
| Field | Value |
|-------|-------|
| initial_followers | 10 |
| expected_followers | 9 |

## Edge Cases
- Count cannot go negative

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
