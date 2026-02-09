# TC-516: Starting Creates Goal Instances

## Linked User Story
- [US-504](../USER-STORY/US-504-start-group-goal.md)

## Test Type
Integration

## Priority
Critical

## Preconditions
- Template with 3 participants
- Participants have capacity

## Test Steps
1. Start group goal
2. Check participant 1's goals
3. Check participant 2's goals
4. Check participant 3's goals

## Expected Results
- Each participant has new goal instance
- Goal structure matches template
- Goals are active status
- Progress starts at 0%

## Test Data
| Field | Value |
|-------|-------|
| participants | 3 |
| instances_created | 3 |

## Edge Cases
- Participant at limit

## Automation Status
- [ ] Automated in: `test/heads_up/coach_center_test.exs`
