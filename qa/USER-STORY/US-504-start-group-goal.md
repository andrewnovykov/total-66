# US-504: Start Group Goal

## User Story
As a coach,
I want to start a group goal,
So that participants receive their individual goal instances.

## Acceptance Criteria
- [ ] AC-1: Coach can click "Start Group Goal" button
- [ ] AC-2: Confirmation dialog shown before start
- [ ] AC-3: Each participant receives individual goal instance
- [ ] AC-4: Goal instances are copies of the template
- [ ] AC-5: Goal instances have status "active" (if under 3-item limit)
- [ ] AC-6: Template becomes read-only after start
- [ ] AC-7: Group goal status changes to "active"

## User Types
- Coach

## Priority
Critical

## Source
- Requirement: project_doc/docs/requirements/04-features/13-coach-center-group-goals.md
- Requirement: project_doc/docs/requirements/03-features-mvp.md

## Linked Test Cases
- [TC-515](../Test-Case/TC-515-start-group-goal-success.md)
- [TC-516](../Test-Case/TC-516-start-creates-instances.md)
- [TC-517](../Test-Case/TC-517-start-template-readonly.md)
- [TC-518](../Test-Case/TC-518-start-participant-at-limit.md)

## Notes
- Starting triggers goal instance creation for all participants
- Participants at 3-item limit may have blocked status
