# TC-241: Follow Friends-Only User

## Linked User Story
- [US-209](../USER-STORY/US-209-follow-privacy.md)

## Test Type
Integration / API

## Priority
High

## Preconditions
- User A is logged in
- User B has privacy set to "friends_only"

## Test Steps
### Scenario 1: Not Friends
1. Navigate to User B's profile (not friends with User A)
2. Attempt to click "Follow" button
3. Verify follow is denied with message "Must be friends to follow this user"

### Scenario 2: Are Friends
4. Create friendship between User A and User B
5. Navigate to User B's profile
6. Click "Follow" button
7. Verify follow succeeds

## Expected Results
- Non-friends cannot follow friends-only users
- Error message explains requirement
- Friends can follow successfully
- Follow relationship created when friends

## Test Data
| Field | Value |
|-------|-------|
| follower | user_a@example.com |
| friends_only_user | friends_only@example.com |
| privacy_setting | friends_only |

## Edge Cases
- Friendship removed after follow: follow may remain or be removed
- Following someone then they change privacy

## Automation Status
- [ ] Automated in: `test/heads_up_web/controllers/api/user_api_test.exs`
