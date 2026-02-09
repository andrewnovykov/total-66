# TC-605: People Sort Options

## Linked User Story
- [US-600](../USER-STORY/US-600-people-directory.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Multiple users with varying stats exist
- User is on /people page

## Test Steps
1. Select "Recommended" sort (logged-in only)
2. Select "Most active" sort
3. Select "Most followed" sort
4. Select "Newest" sort
5. Verify order changes appropriately

## Expected Results
- Recommended shows personalized order
- Most active orders by activity count
- Most followed orders by follower count
- Newest orders by registration date

## Test Data
| Field | Value |
|-------|-------|
| sort_options | recommended, most_active, most_followed, newest |

## Edge Cases
- Recommended not available for guests
- Users with same stats

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
