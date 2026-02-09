# TC-231: Follow Counts Display

## Linked User Story
- [US-207](../USER-STORY/US-207-user-following.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- User profile exists
- User has followers and following

## Test Steps
1. Navigate to user profile
2. View follower count
3. View following count
4. Click to see lists

## Expected Results
- Follower count displayed
- Following count displayed
- Lists show actual users

## Test Data
| Field | Value |
|-------|-------|
| followers | 10 |
| following | 5 |

## Edge Cases
- User with no followers/following

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/follow_live_test.exs`
