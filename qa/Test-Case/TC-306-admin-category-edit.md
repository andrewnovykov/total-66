# TC-306: Admin Edit Category

## Linked User Story
- [US-301](../USER-STORY/US-301-admin-category-management.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- Admin user is logged in
- Category exists

## Test Steps
1. Navigate to admin categories page
2. Click edit on existing category
3. Change name
4. Save changes

## Expected Results
- Category is updated
- Changes reflected everywhere
- Existing goals maintain category

## Test Data
| Field | Value |
|-------|-------|
| old_name | Health |
| new_name | Health & Wellness |

## Edge Cases
- Edit category with active goals

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/category_live_test.exs`
