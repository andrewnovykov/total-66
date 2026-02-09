# TC-316: Admin Analytics - Activity

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
2. View activity metrics section

## Expected Results
- Posts count displayed
- Likes count shown
- Comments count visible
- Activity trends chart

## Test Data
| Field | Value |
|-------|-------|
| total_posts | 2000 |
| total_likes | 10000 |

## Edge Cases
- Low activity periods

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/analytics_live_test.exs`
