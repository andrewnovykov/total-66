# TC-505: Template Creation with Phases and Steps

## Linked User Story
- [US-501](../USER-STORY/US-501-create-group-goal-template.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- Coach is logged in

## Test Steps
1. Navigate to template creation
2. Enter title
3. Add Phase 1: "Foundation"
4. Add steps to Phase 1
5. Add Phase 2: "Building"
6. Add steps to Phase 2
7. Save template

## Expected Results
- Template created with all phases
- Each phase has its steps
- Order is preserved
- Structure displayed correctly

## Test Data
| Field | Value |
|-------|-------|
| phase_1 | Foundation |
| phase_1_steps | 5 |
| phase_2 | Building |
| phase_2_steps | 5 |

## Edge Cases
- Single phase template

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/template_live_test.exs`
