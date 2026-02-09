# TC-312: Admin Delete Content

## Linked User Story
- [US-302](../USER-STORY/US-302-admin-content-moderation.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Admin user is logged in
- Flagged content exists

## Test Steps
1. Navigate to moderation queue
2. Select flagged item
3. Click "Delete Permanently"
4. Confirm action

## Expected Results
- Content is permanently deleted
- Item removed from queue
- Cannot be restored
- Action is logged

## Test Data
| Field | Value |
|-------|-------|
| moderation_status | flagged |
| final_status | deleted |

## Edge Cases
- Delete content with comments

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/moderation_live_test.exs`
