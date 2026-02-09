# TC-105: Goal Creation with Missing Target Date

## Linked User Story
- [US-100](../USER-STORY/US-100-goal-creation.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User has fewer than 3 active items

## Test Steps
1. Navigate to goal creation form
2. Enter title: "Test Goal"
3. Select category
4. Set visibility
5. Leave target date empty
6. Click Save

## Expected Results
- Goal creation fails
- Error message: "Target date can't be blank"
- User remains on creation form

## Test Data
| Field | Value |
|-------|-------|
| title | Test Goal |
| target_date | (empty) |
| category | Programming |
| visibility | public |

## Edge Cases
- Past date validation
- Very far future date

## Bug Reference
- qa/BUGS/BUG-7.md

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
