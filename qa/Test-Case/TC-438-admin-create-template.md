# TC-438: Admin Create Challenge Template

## Linked User Story
- [US-410](../USER-STORY/US-410-admin-create-challenge-template.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Admin user is logged in

## Test Steps
1. Navigate to admin challenge management
2. Click "Create Template"
3. Enter title and description
4. Add phases and steps
5. Set duration
6. Publish template

## Expected Results
- Template is created
- Template appears in admin list
- Template visible to users
- Phases and steps saved

## Test Data
| Field | Value |
|-------|-------|
| title | 30-Day Fitness Challenge |
| duration | 30 days |
| phases | 3 |
| steps_per_phase | 10 |

## Edge Cases
- Save as draft

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/challenge_live_test.exs`
