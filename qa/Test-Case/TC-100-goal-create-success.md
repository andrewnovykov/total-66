# TC-100: Successful Goal Creation

## Linked User Story
- [US-100](../USER-STORY/US-100-goal-creation.md)

## Test Type
E2E / LiveView

## Priority
Critical

## Preconditions
- User is logged in
- User has fewer than 3 active items
- Category exists

## Test Steps
1. Navigate to My Goals
2. Click "Create Goal" button
3. Enter title: "Learn Elixir"
4. Enter description: "Master Elixir programming"
5. Select category
6. Set visibility to "public"
7. Click Save

## Expected Results
- Goal is created successfully
- Goal appears in My Goals list
- Goal detail page is shown
- Status is "active"

## Test Data
| Field | Value |
|-------|-------|
| title | Learn Elixir |
| description | Master Elixir programming |
| visibility | public |
| category | Programming |

## Edge Cases
- Goal with minimum fields only
- Very long title

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
