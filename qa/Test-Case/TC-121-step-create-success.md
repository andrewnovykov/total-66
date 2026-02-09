# TC-121: Successfully Create Step

## Linked User Story
- [US-105](../USER-STORY/US-105-goal-steps.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User owns the goal
- Goal has fewer than 20 steps

## Test Steps
1. Navigate to owned goal detail
2. Click "Add Step" button
3. Enter step title: "Complete chapter 1"
4. Enter optional description
5. Save step

## Expected Results
- Step is created
- Step appears in goal steps list
- Progress is recalculated

## Test Data
| Field | Value |
|-------|-------|
| title | Complete chapter 1 |
| description | Read and take notes |

## Edge Cases
- Step with no description
- Special characters in title

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
