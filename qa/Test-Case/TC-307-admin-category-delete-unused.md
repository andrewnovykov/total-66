# TC-307: Admin Delete Unused Category

## Linked User Story
- [US-301](../USER-STORY/US-301-admin-category-management.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Admin user is logged in
- Category exists with no goals

## Test Steps
1. Navigate to admin categories page
2. Click delete on unused category
3. Confirm deletion

## Expected Results
- Category is deleted
- Category removed from list
- No longer available for new goals

## Test Data
| Field | Value |
|-------|-------|
| category_goals | 0 |

## Edge Cases
- Delete immediately after creation

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/category_live_test.exs`
