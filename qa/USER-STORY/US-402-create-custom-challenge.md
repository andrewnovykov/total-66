# US-402: Create Custom Challenge

## User Story
As a registered user,
I want to create my own custom challenge with scheduled tasks,
So that I can build my own habit routines.

## Acceptance Criteria
- [ ] AC-1: User can access "Create Challenge" option
- [ ] AC-2: User must provide title (required)
- [ ] AC-3: User can add optional description
- [ ] AC-4: User can add tasks with schedules
- [ ] AC-5: Schedule options: daily, twice-week, every-other-day, Mon-Fri, custom weekdays
- [ ] AC-6: Challenge is created with status "active"
- [ ] AC-7: Challenge counts toward max 3 active items
- [ ] AC-8: User cannot create if at 3 active items
- [ ] AC-9: Challenge is created as a personal challenge (`is_template=false`), not as a template
- [ ] AC-10: Creator is automatically joined as a participant upon creation
- [ ] AC-11: Show page displays daily check-in UI, feed, and progress tracking for creator

## User Types
- Registered User

## Priority
High

## Source
- Requirement: project_doc/docs/requirements/04-features/05-challenges.md
- Requirement: project_doc/docs/requirements/03-features-mvp.md

## Linked Test Cases
- [TC-406](../Test-Case/TC-406-create-custom-success.md)
- [TC-407](../Test-Case/TC-407-create-custom-missing-title.md)
- [TC-408](../Test-Case/TC-408-create-custom-max-limit.md)
- [TC-409](../Test-Case/TC-409-create-custom-with-tasks.md)
- [TC-450](../Test-Case/TC-450-custom-challenge-is-personal.md)

## Notes
- User-created challenges are fully editable by creator
- Tasks can have different recurrence patterns
