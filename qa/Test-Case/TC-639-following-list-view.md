# TC-639: View Following List

## Linked User Story
- [US-607](../USER-STORY/US-607-followers-following-list.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User is following other users

## Test Steps
1. Navigate to profile page
2. Click on following count/link
3. Observe following list modal/page
4. Verify followed user information

## Expected Results
- Following list opens
- Shows user cards for each followed user
- Displays avatar, name, bio
- Shows unfollow action for each

## Test Data
| Field | Value |
|-------|-------|
| following_count | 15 |
| list_type | following |

## Edge Cases
- User not following anyone

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
