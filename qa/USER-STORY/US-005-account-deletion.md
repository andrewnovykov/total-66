# US-005: Account Deletion

## User Story
As a registered user,
I want to delete my account,
So that I can remove my data from the platform.

## Acceptance Criteria
- [ ] AC-1: User can access account deletion option in settings
- [ ] AC-2: Confirmation dialog is shown before deletion
- [ ] AC-3: User must enter password to confirm deletion
- [ ] AC-4: Account and associated data are removed/anonymized
- [ ] AC-5: User is logged out and redirected to home

## User Types
- Registered User

## Priority
Medium

## Source
- CLAUDE.md: Profile Management section

## Linked Test Cases
- [TC-017](../Test-Case/TC-017-account-deletion-success.md)
- [TC-018](../Test-Case/TC-018-account-deletion-wrong-password.md)
- [TC-019](../Test-Case/TC-019-account-deletion-cancel.md)

## Notes
- Soft delete may be used to preserve referential integrity
