# TC-638: View Followers List

## Linked User Story
- [US-607](../USER-STORY/US-607-followers-following-list.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User has followers

## Test Steps
1. Navigate to profile page
2. Click on followers count/link
3. Observe followers list modal/page
4. Verify follower information displayed

## Expected Results
- Followers list opens
- Shows user cards for each follower
- Displays avatar, name, bio
- Shows follow/friend actions for each

## Test Data
| Field | Value |
|-------|-------|
| followers_count | 10 |
| list_type | followers |

## Edge Cases
- User has no followers

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
