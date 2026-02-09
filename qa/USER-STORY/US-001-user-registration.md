# US-001: User Registration

## User Story
As a visitor,
I want to register with my email, password, and username,
So that I can access the platform and create goals.

## Acceptance Criteria
- [ ] AC-1: User can access registration page from login screen
- [ ] AC-2: User must provide unique email address
- [ ] AC-3: User must provide unique username
- [ ] AC-4: User must provide password with confirmation
- [ ] AC-5: After successful registration, user is logged in immediately
- [ ] AC-6: User is redirected to home page after registration
- [ ] AC-7: Optional profile photo and bio can be added

## User Types
- Guest (becoming Registered User)

## Priority
High

## Source
- Requirement: project_doc/docs/requirements/04-features/01-authentication.md
- Requirement: project_doc/docs/requirements/05-business-rules.md

## Linked Test Cases
- [TC-001](../Test-Case/TC-001-registration-valid-user.md)
- [TC-002](../Test-Case/TC-002-registration-duplicate-email.md)
- [TC-003](../Test-Case/TC-003-registration-duplicate-username.md)
- [TC-004](../Test-Case/TC-004-registration-password-mismatch.md)
- [TC-005](../Test-Case/TC-005-registration-missing-fields.md)

## Notes
- Email verification is not required for MVP
- Social login is planned for future releases
