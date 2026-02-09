# TC-237: Connections Stats Summary

## Linked User Story
- [US-208](../USER-STORY/US-208-connections-manager.md)

## Test Type
LiveView / Integration

## Priority
Medium

## Preconditions
- User is logged in
- User has known connection counts

## Test Steps
1. Navigate to `/connections`
2. Verify stats bar shows: Following (3), Followers (1), Friends (0), Requests (0)
3. Click on "Following" count
4. Verify Following tab becomes active
5. Click on "Followers" count
6. Verify Followers tab becomes active
7. Click on "Friends" count
8. Verify Friends tab becomes active
9. Click on "Requests" count
10. Verify Requests tab becomes active

## Expected Results
- All four counts display correctly
- Clicking any count switches to corresponding tab
- Active tab is visually highlighted
- Counts match actual data

## Test Data
| Field | Value |
|-------|-------|
| following_count | 3 |
| followers_count | 1 |
| friends_count | 0 |
| requests_count | 0 |

## Edge Cases
- Zero counts display as "0" not empty
- Large counts (100+) display correctly
- Badge indicator on Requests if > 0

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
