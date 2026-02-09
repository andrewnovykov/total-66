# TC-602: People Filter by Activity Level

## Linked User Story
- [US-600](../USER-STORY/US-600-people-directory.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Users with varying activity levels exist
- User is on /people page

## Test Steps
1. Select "Highly active" filter
2. Observe filtered results
3. Select "Active this week" filter
4. Observe filtered results
5. Select "Recently joined" filter
6. Observe filtered results

## Expected Results
- Highly active shows users with frequent activity
- Active this week shows users active in last 7 days
- Recently joined shows newest users
- Filters can be combined with search

## Test Data
| Field | Value |
|-------|-------|
| filter_options | highly_active, active_week, recently_joined |

## Edge Cases
- No users match filter
- Filter with search combination

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
