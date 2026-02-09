# TC-305: Admin Create Category

## Linked User Story
- [US-301](../USER-STORY/US-301-admin-category-management.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Admin user is logged in

## Test Steps
1. Navigate to admin categories page
2. Click "New Category" button
3. Enter name: "Health & Fitness"
4. Enter description
5. Save category

## Expected Results
- Category is created
- Category appears in list
- Category available in goal creation

## Test Data
| Field | Value |
|-------|-------|
| name | Health & Fitness |
| description | Goals related to health and fitness |

## Edge Cases
- Duplicate category name
- Empty name

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/category_live_test.exs`
