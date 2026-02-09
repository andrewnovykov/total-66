# TC-313: Admin Moderation Audit Trail

## Linked User Story
- [US-302](../USER-STORY/US-302-admin-content-moderation.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Admin user is logged in
- Moderation actions have occurred

## Test Steps
1. Navigate to moderation history
2. View audit trail
3. Filter by action type
4. View details of action

## Expected Results
- All actions are logged
- Timestamp and admin shown
- Action details visible
- Filter works correctly

## Test Data
| Field | Value |
|-------|-------|
| action_types | approve, spam, delete |

## Edge Cases
- Very long audit history

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/moderation_live_test.exs`
