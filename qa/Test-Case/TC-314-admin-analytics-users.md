# TC-314: Admin Analytics - Users

## Linked User Story
- [US-303](../USER-STORY/US-303-admin-analytics.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Admin user is logged in

## Test Steps
1. Navigate to admin dashboard
2. View user metrics section

## Expected Results
- Total users count displayed
- Active users (30 days) shown
- New signups graph visible
- Metrics update in real-time

## Test Data
| Field | Value |
|-------|-------|
| total_users | 1000 |
| active_users | 500 |

## Edge Cases
- New platform (few users)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/analytics_live_test.exs`
