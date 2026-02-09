# US-503: Add Participants to Group Goal

## User Story
As a coach,
I want to add participants to my group goal,
So that they can join the structured program.

## Acceptance Criteria
- [ ] AC-1: Coach can search for users to add
- [ ] AC-2: Coach can add multiple participants
- [ ] AC-3: Participant list is shown before start
- [ ] AC-4: Coach can remove participants before start
- [ ] AC-5: Cannot add same participant twice
- [ ] AC-6: Participants receive notification (future)

## User Types
- Coach

## Priority
High

## Source
- Requirement: project_doc/docs/requirements/04-features/13-coach-center-group-goals.md
- Requirement: project_doc/docs/requirements/03-features-mvp.md

## Linked Test Cases
- [TC-511](../Test-Case/TC-511-add-participant-success.md)
- [TC-512](../Test-Case/TC-512-add-participant-search.md)
- [TC-513](../Test-Case/TC-513-add-participant-duplicate.md)
- [TC-514](../Test-Case/TC-514-remove-participant-before-start.md)

## Notes
- Participants are validated users
- Addition before start doesn't create goal instances yet
