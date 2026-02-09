# US-300: Admin User Management

## User Story
As an admin,
I want to view and manage all users,
So that I can maintain platform integrity and handle issues.

## Acceptance Criteria
- [ ] AC-1: Admin can view list of all users
- [ ] AC-2: Admin can search users by name/email
- [ ] AC-3: Admin can view user details and activity
- [ ] AC-4: Admin can block users
- [ ] AC-5: Admin can unblock users
- [ ] AC-6: Admin can create new users
- [ ] AC-7: Blocked users cannot log in
- [ ] AC-8: Blocked user content is hidden from public

## User Types
- Admin

## Priority
High

## Source
- PRD: project/ROADMAP.md (Phase 3.6)
- Requirement: project_doc/docs/requirements/04-features/17-admin-dashboard.md

## Linked Test Cases
- [TC-300](../Test-Case/TC-300-admin-user-list.md)
- [TC-301](../Test-Case/TC-301-admin-user-search.md)
- [TC-302](../Test-Case/TC-302-admin-user-block.md)
- [TC-303](../Test-Case/TC-303-admin-user-unblock.md)
- [TC-304](../Test-Case/TC-304-blocked-user-login-denied.md)

## Notes
- Blocking is reversible
- Activity monitoring helps identify issues
