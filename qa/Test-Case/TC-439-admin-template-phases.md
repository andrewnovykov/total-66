# TC-439: Admin Define Template Phases

## Linked User Story
- [US-410](../USER-STORY/US-410-admin-create-challenge-template.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Admin user is logged in
- Creating new template

## Test Steps
1. Start template creation
2. Add phase 1: "Foundation"
3. Add steps to phase 1
4. Add phase 2: "Building"
5. Add steps to phase 2
6. Save template

## Expected Results
- Multiple phases created
- Each phase has steps
- Order is preserved
- Phases are editable

## Test Data
| Field | Value |
|-------|-------|
| phase_1 | Foundation |
| phase_2 | Building |
| steps_per_phase | 5 |

## Edge Cases
- Single phase challenge

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/challenge_live_test.exs`
