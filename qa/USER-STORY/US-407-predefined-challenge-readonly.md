# US-407: Predefined Challenge Read-Only

## User Story
As a predefined challenge participant,
I want the challenge structure to be locked,
So that I follow the intended program exactly.

## Acceptance Criteria
- [ ] AC-1: Participant cannot edit challenge title
- [ ] AC-2: Participant cannot edit phases
- [ ] AC-3: Participant cannot edit steps
- [ ] AC-4: Participant cannot add/remove steps
- [ ] AC-5: Edit buttons are hidden for participants
- [ ] AC-6: Only completion actions available

## User Types
- Registered User (Challenge Participant)

## Priority
High

## Source
- Requirement: project_doc/docs/requirements/04-features/05-challenges.md
- Requirement: project_doc/docs/requirements/03-features-mvp.md

## Linked Test Cases
- [TC-427](../Test-Case/TC-427-predefined-no-edit-button.md)
- [TC-428](../Test-Case/TC-428-predefined-api-edit-denied.md)
- [TC-429](../Test-Case/TC-429-predefined-complete-only.md)

## Notes
- Template integrity is critical for predefined challenges
- Admin can edit templates separately
