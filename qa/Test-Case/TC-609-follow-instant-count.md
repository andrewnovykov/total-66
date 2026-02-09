# TC-609: Follow Instant Count Update

## Linked User Story
- [US-601](../USER-STORY/US-601-follow-user.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Target user exists with known follower count

## Test Steps
1. Note target user's follower count
2. Click "Follow" button
3. Observe count immediately after click
4. Refresh page and verify count

## Expected Results
- Count updates immediately without refresh
- Count persists after refresh
- Own following count also updates

## Test Data
| Field | Value |
|-------|-------|
| initial_followers | 5 |
| expected_followers | 6 |

## Edge Cases
- Rapid follow/unfollow clicks

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
