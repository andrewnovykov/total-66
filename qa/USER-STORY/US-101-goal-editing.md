# US-101: Goal Editing

## User Story
As a goal owner,
I want to edit my goal details,
So that I can update information as my plan evolves.

## Acceptance Criteria
- [ ] AC-1: Only goal owner can see edit option
- [ ] AC-2: Owner can edit title and description
- [ ] AC-3: Owner can change category
- [ ] AC-4: Owner can change visibility
- [ ] AC-5: Owner can update target date
- [ ] AC-6: Owner can change goal image
- [ ] AC-7: Frozen goals cannot be edited
- [ ] AC-8: Changes are saved and reflected immediately

## User Types
- Registered User (Goal Owner)

## Priority
High

## Source
- PRD: project/ROADMAP.md (Phase 1.1)
- Requirement: project_doc/docs/requirements/04-features/04-goals.md

## Linked Test Cases
- [TC-105](../Test-Case/TC-105-goal-edit-owner-success.md)
- [TC-106](../Test-Case/TC-106-goal-edit-non-owner-denied.md)
- [TC-107](../Test-Case/TC-107-goal-edit-frozen-blocked.md)
- [TC-108](../Test-Case/TC-108-goal-edit-image.md)

## Notes
- Server-side ownership validation is critical
- Frozen goals must be unfrozen before editing
