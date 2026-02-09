# US-401: Join Predefined Challenge

## User Story
As a registered user,
I want to join a predefined challenge,
So that I can follow a structured program with set phases and steps.

## Acceptance Criteria
- [ ] AC-1: User can click "Join" on a predefined challenge
- [ ] AC-2: Challenge is added to user's active items
- [ ] AC-3: Challenge counts toward max 3 active items limit
- [ ] AC-4: User cannot join if at 3 active items
- [ ] AC-5: Challenge appears in "My Challenges" section
- [ ] AC-6: Challenge detail shows phases and steps (read-only)
- [ ] AC-7: Progress tracking begins immediately

## User Types
- Registered User

## Priority
High

## Source
- Requirement: project_doc/docs/requirements/04-features/05-challenges.md
- Requirement: project_doc/docs/requirements/03-features-mvp.md

## Linked Test Cases
- [TC-403](../Test-Case/TC-403-join-predefined-success.md)
- [TC-404](../Test-Case/TC-404-join-predefined-max-limit.md)
- [TC-405](../Test-Case/TC-405-join-predefined-already-active.md)

## Notes
- Predefined challenges have template-locked phases/steps
- User cannot edit challenge structure
