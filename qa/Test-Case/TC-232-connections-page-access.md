# TC-232: Connections Page Access

## Linked User Story
- [US-208](../USER-STORY/US-208-connections-manager.md)

## Test Type
LiveView / Integration

## Priority
High

## Preconditions
- User is registered in the system
- User is logged in

## Test Steps
1. Navigate to `/connections`
2. Verify the page loads successfully
3. Verify the stats summary bar is visible
4. Verify the tab navigation is visible (Following, Followers, Friends, Requests)

## Expected Results
- Page loads without error
- Stats summary shows 4 counts: Following, Followers, Friends, Requests
- Tab navigation is present and functional
- First tab (Following) is active by default

## Test Data
| Field | Value |
|-------|-------|
| user | test@example.com |

## Edge Cases
- Guest user redirected to login page
- New user with no connections sees zero counts

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/connections_live_test.exs`
