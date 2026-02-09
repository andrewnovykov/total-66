# US-103: Goal Status Management

## User Story
As a goal owner,
I want to change my goal's status,
So that I can freeze, complete, or mark goals as failed.

## Acceptance Criteria
- [ ] AC-1: Goal has statuses: active, frozen, completed, failed
- [ ] AC-2: Owner can freeze an active goal
- [ ] AC-3: Owner can unfreeze a frozen goal
- [ ] AC-4: Owner can mark goal as completed
- [ ] AC-5: Owner can mark goal as failed (requires reason)
- [ ] AC-6: Frozen goals cannot be edited
- [ ] AC-7: Only active goals count toward 3-item limit
- [ ] AC-8: Failed goals display failure reason
- [ ] AC-9: Failed goals cannot be frozen (BUG-2)
- [ ] AC-10: Failed goals cannot be edited (BUG-2)

## User Types
- Registered User (Goal Owner)

## Priority
High

## Source
- PRD: project/ROADMAP.md (Phase 1.2, 1.3)
- Requirement: project_doc/docs/requirements/04-features/04-goals.md

## Linked Test Cases
- [TC-112](../Test-Case/TC-112-goal-freeze-success.md)
- [TC-113](../Test-Case/TC-113-goal-unfreeze-success.md)
- [TC-114](../Test-Case/TC-114-goal-complete-success.md)
- [TC-115](../Test-Case/TC-115-goal-fail-with-reason.md)
- [TC-116](../Test-Case/TC-116-goal-fail-without-reason.md)
- [TC-117](../Test-Case/TC-117-goal-freeze-failed-blocked.md)
- [TC-118](../Test-Case/TC-118-goal-edit-failed-blocked.md)

## Notes
- Failure reason helps with reflection and learning
- Status changes are logged for history
