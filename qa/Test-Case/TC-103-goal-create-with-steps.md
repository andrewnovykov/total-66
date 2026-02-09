# TC-103: Goal Creation with Steps

## Linked User Story
- [US-100](../USER-STORY/US-100-goal-creation.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- User has capacity for new goal

## Test Steps
1. Navigate to goal creation form
2. Fill in title and basic info
3. Add step 1: "Complete tutorial"
4. Add step 2: "Build first project"
5. Add step 3: "Deploy to production"
6. Save goal

## Expected Results
- Goal is created with all steps
- Steps appear in goal detail
- Progress shows 0% (no steps completed)

## Test Data
| Field | Value |
|-------|-------|
| title | Learn Phoenix |
| step_1 | Complete tutorial |
| step_2 | Build first project |
| step_3 | Deploy to production |

## Edge Cases
- Maximum 20 steps
- Steps with long descriptions

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
