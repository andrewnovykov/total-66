# TC-423: Edit Custom Challenge Title

## Linked User Story
- [US-406](../USER-STORY/US-406-edit-custom-challenge.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User owns custom challenge

## Test Steps
1. Navigate to owned custom challenge
2. Click Edit button
3. Change title
4. Save changes

## Expected Results
- Title is updated
- Change is saved
- New title displayed everywhere

## Test Data
| Field | Value |
|-------|-------|
| old_title | Morning Routine |
| new_title | Morning Power Routine |

## Edge Cases
- Empty title (should fail)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
