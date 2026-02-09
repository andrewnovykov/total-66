# US-403: Challenge Task Scheduling

## User Story
As a challenge creator,
I want to set different schedules for each task,
So that I can customize when tasks should be completed.

## Acceptance Criteria
- [ ] AC-1: Task can be set to "daily" (every day)
- [ ] AC-2: Task can be set to "twice-week" (2 days per week)
- [ ] AC-3: Task can be set to "every-other-day" (alternating days)
- [ ] AC-4: Task can be set to "Mon-Fri" (weekdays only)
- [ ] AC-5: Task can be set to "custom weekdays" (specific days selected)
- [ ] AC-6: Tasks appear on scheduled days only
- [ ] AC-7: Schedule can be edited after creation

## User Types
- Registered User (Challenge Creator)

## Priority
Medium

## Source
- PRD: project/ROADMAP.md (Phase 6.2)
- Requirement: project_doc/docs/requirements/04-features/05-challenges.md

## Linked Test Cases
- [TC-410](../Test-Case/TC-410-task-schedule-daily.md)
- [TC-411](../Test-Case/TC-411-task-schedule-twice-week.md)
- [TC-412](../Test-Case/TC-412-task-schedule-every-other-day.md)
- [TC-413](../Test-Case/TC-413-task-schedule-weekdays.md)
- [TC-414](../Test-Case/TC-414-task-schedule-custom.md)

## Notes
- Schedule determines when task appears as "due"
- Missed tasks should be tracked
