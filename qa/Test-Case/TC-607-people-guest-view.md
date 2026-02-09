# TC-607: People Page Guest View

## Linked User Story
- [US-600](../USER-STORY/US-600-people-directory.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is not logged in (guest)
- People exist in database

## Test Steps
1. Navigate to /people as guest
2. Observe available features
3. Try to interact with social actions

## Expected Results
- Page loads successfully
- Search and filters work
- Follow button shows "Sign in to follow"
- Friend request button not available
- Friendship filter hidden
- Recommended sort hidden

## Test Data
| Field | Value |
|-------|-------|
| user_state | guest |

## Edge Cases
- Guest clicks follow prompts login

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
