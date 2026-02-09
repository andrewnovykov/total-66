# TC-239: Remove Follower

## Linked User Story
- [US-207](../USER-STORY/US-207-user-following.md)
- [US-208](../USER-STORY/US-208-connections-manager.md)

## Test Type
Integration

## Priority
Medium

## Preconditions
- User A is logged in
- User B is following User A

## Test Steps
1. Navigate to `/connections`
2. Click on "Followers" tab
3. Locate User B in the followers list
4. Click "Remove" button on User B's card
5. Confirm the action if prompted
6. Verify User B is removed from the followers list
7. Verify Followers count decreases
8. Login as User B
9. Navigate to User B's Following tab
10. Verify User A no longer appears

## Expected Results
- Follower is removed successfully
- Follower count updates
- Removed follower no longer sees relationship
- Removed follower may be blocked from re-following (implementation dependent)

## Test Data
| Field | Value |
|-------|-------|
| user_a | followed@example.com |
| user_b | follower@example.com |

## Edge Cases
- Cannot remove someone who isn't a follower
- Toast confirms removal
- May show confirmation dialog before removal

## Automation Status
- [ ] Automated in: `test/heads_up/accounts_test.exs`
