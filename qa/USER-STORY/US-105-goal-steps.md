# US-105: Goal Steps Management

## User Story
As a goal owner,
I want to add and manage steps within my goal,
So that I can break down my goal into actionable tasks.

## Acceptance Criteria
- [ ] AC-1: Owner can add steps to a goal (max 20)
- [ ] AC-2: Each step has title and optional description
- [ ] AC-3: Steps can have target dates
- [ ] AC-4: Owner can edit step details
- [ ] AC-5: Owner can mark steps as completed
- [ ] AC-6: Owner can reorder steps
- [ ] AC-7: Owner can delete steps
- [ ] AC-8: Step completion updates goal progress

## User Types
- Registered User (Goal Owner)

## Priority
High

## Source
- CLAUDE.md: GoalStep Schema
- Requirement: project_doc/docs/requirements/03-features-mvp.md

## Linked Test Cases
- [TC-121](../Test-Case/TC-121-step-create-success.md)
- [TC-122](../Test-Case/TC-122-step-create-max-limit.md)
- [TC-123](../Test-Case/TC-123-step-complete.md)
- [TC-124](../Test-Case/TC-124-step-reorder.md)
- [TC-125](../Test-Case/TC-125-step-delete.md)

## Notes
- Maximum 20 steps per goal
- Progress calculated from completed steps percentage
