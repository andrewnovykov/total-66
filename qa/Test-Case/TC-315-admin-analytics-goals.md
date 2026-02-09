# TC-315: Admin Analytics - Goals

## Linked User Story
- [US-303](../USER-STORY/US-303-admin-analytics.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- Admin user is logged in

## Test Steps
1. Navigate to admin dashboard
2. View goals metrics section

## Expected Results
- Total goals count displayed
- Active goals shown
- Completed goals count
- Goals by category chart

## Test Data
| Field | Value |
|-------|-------|
| total_goals | 500 |
| active_goals | 200 |

## Edge Cases
- No goals created yet

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/analytics_live_test.exs`
