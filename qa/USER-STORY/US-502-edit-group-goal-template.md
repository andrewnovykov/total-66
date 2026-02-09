# US-502: Edit Group Goal Template

## User Story
As a coach,
I want to edit my group goal template,
So that I can refine the program before starting it.

## Acceptance Criteria
- [ ] AC-1: Coach can edit template title and description
- [ ] AC-2: Coach can add/edit/remove phases
- [ ] AC-3: Coach can add/edit/remove steps
- [ ] AC-4: Coach can change category
- [ ] AC-5: Coach can update duration
- [ ] AC-6: Cannot edit template after group goal is started
- [ ] AC-7: Only template owner can edit

## User Types
- Coach (Template Owner)

## Priority
Medium

## Source
- Requirement: project_doc/docs/requirements/04-features/13-coach-center-group-goals.md

## Linked Test Cases
- [TC-507](../Test-Case/TC-507-template-edit-success.md)
- [TC-508](../Test-Case/TC-508-template-edit-add-phase.md)
- [TC-509](../Test-Case/TC-509-template-edit-after-start-denied.md)
- [TC-510](../Test-Case/TC-510-template-edit-non-owner-denied.md)

## Notes
- Templates become read-only once a group goal is started
- Draft templates can be freely edited
