# TC-308: Cannot Delete Category In Use

## Linked User Story
- [US-301](../USER-STORY/US-301-admin-category-management.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Admin user is logged in
- Category has active goals

## Test Steps
1. Navigate to admin categories page
2. Attempt to delete category with goals
3. Observe result

## Expected Results
- Deletion is blocked
- Error message explains why
- Category remains unchanged

## Test Data
| Field | Value |
|-------|-------|
| category_goals | 5 |

## Edge Cases
- Only soft-deleted goals using category

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/category_live_test.exs`
