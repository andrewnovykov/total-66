# TC-105: Successful Goal Edit by Owner

## Linked User Story
- [US-101](../USER-STORY/US-101-goal-editing.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User owns the goal
- Goal is not frozen

## Test Steps
1. Navigate to owned goal detail
2. Click Edit button
3. Change title to "Updated Goal Title"
4. Change description
5. Save changes

## Expected Results
- Goal is updated successfully
- New values reflected in detail page
- Success message shown

## Test Data
| Field | Value |
|-------|-------|
| new_title | Updated Goal Title |
| new_description | Updated description |

## Edge Cases
- Edit with no changes
- Edit only title

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
