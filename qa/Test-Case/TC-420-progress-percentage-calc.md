# TC-420: Progress Percentage Calculation

## Linked User Story
- [US-405](../USER-STORY/US-405-challenge-progress-tracking.md)

## Test Type
Unit

## Priority
High

## Preconditions
- Challenge with known task count

## Test Steps
1. Create challenge with 20 tasks
2. Complete 5 tasks
3. Calculate expected percentage
4. Verify displayed percentage

## Expected Results
- 5/20 = 25% displayed
- Calculation is accurate
- Rounds appropriately

## Test Data
| Field | Value |
|-------|-------|
| total_tasks | 20 |
| completed | 5 |
| expected | 25% |

## Edge Cases
- Odd numbers (33.33%)

## Automation Status
- [ ] Automated in: `test/heads_up/challenges_test.exs`
