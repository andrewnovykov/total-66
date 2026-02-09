# US-106: Goal Detail View

## User Story
As a user,
I want to view a goal's detail page,
So that I can see its progress, steps, and activity feed.

## Acceptance Criteria
- [ ] AC-1: Goal detail page shows title and description
- [ ] AC-2: Progress bar shows completion percentage
- [ ] AC-3: Phases and steps are displayed
- [ ] AC-4: Goal feed shows posts and updates
- [ ] AC-5: Like/subscribe buttons visible for non-owners
- [ ] AC-6: Edit button visible for owner only
- [ ] AC-7: Comments section shows engagement
- [ ] AC-8: Visibility rules are enforced

## User Types
- Guest (public goals only)
- Registered User
- Goal Owner

## Priority
High

## Source
- Requirement: project_doc/docs/requirements/04-features/04-goals.md
- Requirement: project_doc/docs/requirements/03-features-mvp.md

## Linked Test Cases
- [TC-126](../Test-Case/TC-126-goal-detail-view-owner.md)
- [TC-127](../Test-Case/TC-127-goal-detail-view-subscriber.md)
- [TC-128](../Test-Case/TC-128-goal-detail-view-guest.md)
- [TC-129](../Test-Case/TC-129-goal-detail-private-denied.md)

## Notes
- Goal feed includes different post types
