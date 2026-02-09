# TC-311: Admin Confirm Spam

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
3. Click "Confirm Spam" button
4. Confirm action

## Expected Results
- Content remains hidden
- Item removed from queue
- Status set to "hidden"
- Action is logged

## Test Data
| Field | Value |
|-------|-------|
| moderation_status | flagged |
| final_status | hidden |

## Edge Cases
- Spam from repeat offender

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/moderation_live_test.exs`
