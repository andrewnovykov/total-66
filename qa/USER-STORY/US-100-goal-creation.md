# US-100: Goal Creation

## User Story
As a registered user,
I want to create a goal with title, description, and phases/steps,
So that I can track my progress toward achieving it.

## Acceptance Criteria
- [ ] AC-1: User can access goal creation from My Goals dashboard
- [ ] AC-2: User must provide a title (required)
- [ ] AC-3: User can add optional description
- [ ] AC-4: User must select a category
- [ ] AC-5: User must set visibility (public/friends/private)
- [ ] AC-6: User can add phases with steps
- [ ] AC-7: User must set target/due date (required)
- [ ] AC-8: User can upload goal image
- [ ] AC-9: Goal is created with status "active"
- [ ] AC-10: User cannot create more than 3 active items

## User Types
- Registered User

## Priority
High

## Source
- PRD: project/ROADMAP.md (Phase 0.2)
- Requirement: project_doc/docs/requirements/04-features/04-goals.md
- Requirement: project_doc/docs/requirements/03-features-mvp.md

## Linked Test Cases
- [TC-100](../Test-Case/TC-100-goal-create-success.md)
- [TC-101](../Test-Case/TC-101-goal-create-missing-title.md)
- [TC-102](../Test-Case/TC-102-goal-create-max-limit.md)
- [TC-103](../Test-Case/TC-103-goal-create-with-steps.md)
- [TC-104](../Test-Case/TC-104-goal-create-visibility-options.md)
- [TC-105](../Test-Case/TC-105-goal-create-missing-target-date.md)

## Notes
- Maximum 3 active items includes goals, challenges, and group goal instances
- Phases/steps encourage structured planning
