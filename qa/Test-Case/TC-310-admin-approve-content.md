# TC-310: Admin Approve Flagged Content

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
1. Navigate to moderation queue
2. Select flagged item
3. Click "Approve" button
4. Confirm action

## Expected Results
- Flag is removed
- Content is visible again
- Item removed from queue
- Action is logged

## Test Data
| Field | Value |
|-------|-------|
| moderation_status | flagged |
| final_status | clean |

## Edge Cases
- Approve item with many reports

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/moderation_live_test.exs`
