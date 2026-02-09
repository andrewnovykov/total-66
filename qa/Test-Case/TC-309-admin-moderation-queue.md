# TC-309: Admin Moderation Queue

## Linked User Story
- [US-302](../USER-STORY/US-302-admin-content-moderation.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Admin user is logged in
- Flagged content exists

## Test Steps
1. Navigate to admin moderation panel
2. View flagged goals queue
3. View flagged posts queue

## Expected Results
- All flagged items displayed
- Report count shown
- Action buttons available
- Details accessible

## Test Data
| Field | Value |
|-------|-------|
| flagged_goals | 5 |
| flagged_posts | 10 |

## Edge Cases
- Empty moderation queue

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/moderation_live_test.exs`
