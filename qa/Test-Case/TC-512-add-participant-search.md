# TC-512: Search for Participants

## Linked User Story
- [US-503](../USER-STORY/US-503-add-participants.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Coach is logged in
- Users exist in system

## Test Steps
1. Navigate to add participants
2. Enter search query: "john"
3. View search results
4. Select user to add

## Expected Results
- Search returns matching users
- Results show name and username
- Can add from search results

## Test Data
| Field | Value |
|-------|-------|
| search_query | john |

## Edge Cases
- No matching users

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/participant_live_test.exs`
