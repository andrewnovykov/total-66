# US-003: User Logout

## User Story
As a logged-in user,
I want to log out of my account,
So that I can secure my session on shared devices.

## Acceptance Criteria
- [ ] AC-1: Logout option is visible in navigation
- [ ] AC-2: Clicking logout ends the session
- [ ] AC-3: User is redirected to login page or home
- [ ] AC-4: Navigation updates to show guest menu items
- [ ] AC-5: Protected pages are no longer accessible

## User Types
- Registered User

## Priority
High

## Source
- Requirement: project_doc/docs/requirements/04-features/01-authentication.md

## Linked Test Cases
- [TC-010](../Test-Case/TC-010-logout-success.md)
- [TC-011](../Test-Case/TC-011-logout-session-invalidation.md)

## Notes
- Session should be fully invalidated on logout
