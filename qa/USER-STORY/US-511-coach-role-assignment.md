# US-511: Coach Role Assignment

## User Story
As an admin,
I want to assign the coach role to users,
So that they can access Coach Center features.

## Acceptance Criteria
- [ ] AC-1: Admin can view user roles
- [ ] AC-2: Admin can assign coach role to a user
- [ ] AC-3: Admin can remove coach role from a user
- [ ] AC-4: Coach role grants Coach Center access
- [ ] AC-5: Removing role removes Coach Center access
- [ ] AC-6: Existing group goals preserved if role removed

## User Types
- Admin

## Priority
High

## Source
- Requirement: project_doc/docs/requirements/05-business-rules.md

## Linked Test Cases
- [TC-542](../Test-Case/TC-542-admin-assign-coach.md)
- [TC-543](../Test-Case/TC-543-admin-remove-coach.md)
- [TC-544](../Test-Case/TC-544-coach-role-grants-access.md)
- [TC-545](../Test-Case/TC-545-removed-coach-no-access.md)

## Notes
- Roles: user, coach, admin
- Coach role is additive (keeps user capabilities)
