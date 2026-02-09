# US-408: Challenge Status Management

## User Story
As a challenge participant,
I want to manage my challenge status,
So that I can complete, fail, or abandon challenges.

## Acceptance Criteria
- [ ] AC-1: Challenge can be marked as completed
- [ ] AC-2: Challenge can be marked as failed
- [ ] AC-3: Challenge can be abandoned (quit early)
- [ ] AC-4: Completed challenges show in history
- [ ] AC-5: Failed/abandoned free up active item slot
- [ ] AC-6: Status change confirmation required

## User Types
- Registered User (Challenge Participant)

## Priority
Medium

## Source
- PRD: project/ROADMAP.md (Phase 6.4)
- Requirement: project_doc/docs/requirements/04-features/05-challenges.md

## Linked Test Cases
- [TC-430](../Test-Case/TC-430-challenge-complete.md)
- [TC-431](../Test-Case/TC-431-challenge-fail.md)
- [TC-432](../Test-Case/TC-432-challenge-abandon.md)
- [TC-433](../Test-Case/TC-433-challenge-history.md)

## Notes
- Status changes affect active item count
- Completion may award XP
