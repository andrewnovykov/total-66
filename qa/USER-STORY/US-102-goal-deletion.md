# US-102: Goal Deletion

## User Story
As a goal owner,
I want to delete my goal,
So that I can remove goals I no longer want to pursue.

## Acceptance Criteria
- [ ] AC-1: Only goal owner can see delete option
- [ ] AC-2: Confirmation dialog is shown before deletion
- [ ] AC-3: Goal is soft-deleted (not removed from database)
- [ ] AC-4: Deleted goals no longer appear in listings
- [ ] AC-5: Deleted goals don't count toward active limit
- [ ] AC-6: Associated posts/comments are preserved but hidden

## User Types
- Registered User (Goal Owner)

## Priority
High

## Source
- PRD: project/ROADMAP.md (Phase 1.2)
- Requirement: project_doc/docs/requirements/04-features/11-my-goals.md

## Linked Test Cases
- [TC-109](../Test-Case/TC-109-goal-delete-owner-success.md)
- [TC-110](../Test-Case/TC-110-goal-delete-non-owner-denied.md)
- [TC-111](../Test-Case/TC-111-goal-delete-confirmation.md)

## Notes
- Soft delete preserves data integrity
- Admins may have restore capability
