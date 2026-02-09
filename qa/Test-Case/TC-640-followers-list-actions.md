# TC-640: Followers List Actions

## Linked User Story
- [US-607](../USER-STORY/US-607-followers-following-list.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Viewing followers list

## Test Steps
1. Open followers list
2. Click "Follow" on a follower not being followed
3. Click "Add Friend" on a non-friend follower
4. Verify actions complete without leaving list

## Expected Results
- Can follow/unfollow from list
- Can send friend request from list
- Actions update in-place
- List stays open after action

## Test Data
| Field | Value |
|-------|-------|
| actions | follow, add_friend |
| context | followers_list |

## Edge Cases
- Action while list is paginating

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
