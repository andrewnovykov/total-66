# TC-406: Successfully Create Custom Challenge

## Linked User Story
- [US-402](../USER-STORY/US-402-create-custom-challenge.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- User is logged in
- User has fewer than 3 active items

## Test Steps
1. Navigate to challenges page
2. Click "Create Challenge"
3. Enter title: "Morning Routine"
4. Add description
5. Add task with schedule
6. Save challenge

## Expected Results
- Challenge is created
- Challenge appears in My Challenges
- Status is "active"
- Active item count increases

## Test Data
| Field | Value |
|-------|-------|
| title | Morning Routine |
| description | Build a healthy morning habit |
| task_count | 1 |

## Edge Cases
- Challenge with no tasks (should fail)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
