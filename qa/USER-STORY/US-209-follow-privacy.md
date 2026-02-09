# US-209: Follow Privacy Restrictions

## User Story
As a user with privacy settings,
I want to control who can follow me,
So that I can protect my content based on my privacy preferences.

## Acceptance Criteria
- [ ] AC-1: Public users can be followed by anyone
- [ ] AC-2: Private users cannot be followed by anyone
- [ ] AC-3: Friends-only users can only be followed by accepted friends
- [ ] AC-4: Users cannot follow themselves
- [ ] AC-5: Appropriate error message shown when follow is denied

## User Types
- Registered User

## Priority
High

## Source
- Requirement: project_doc/docs/requirements/04-features/08-social-graph.md

## Linked Test Cases
- [TC-240](../Test-Case/TC-240-follow-private-user-denied.md)
- [TC-241](../Test-Case/TC-241-follow-friends-only-user.md)
- [TC-242](../Test-Case/TC-242-self-follow-denied.md)

## Notes
- Privacy settings are enforced server-side
- Follow button visibility should reflect allowed actions
