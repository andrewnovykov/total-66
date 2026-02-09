# US-609: Recommended People

## User Story
As a registered user,
I want to see recommended people to follow,
So that I can discover relevant users based on my interests.

## Acceptance Criteria
- [ ] AC-1: Recommended section appears on People page
- [ ] AC-2: Recommendations based on shared categories
- [ ] AC-3: Recommendations based on activity patterns
- [ ] AC-4: Section only visible to logged-in users
- [ ] AC-5: Can follow directly from recommendation
- [ ] AC-6: Recommendations refresh periodically

## User Types
- Registered User

## Priority
Low

## Source
- Requirement: project_doc/docs/design/pages/07-people.md
- ROADMAP: Phase 0.7 - People & Social Graph

## Linked Test Cases
- [TC-647](../Test-Case/TC-647-recommended-people-display.md)
- [TC-648](../Test-Case/TC-648-recommended-category-match.md)
- [TC-649](../Test-Case/TC-649-recommended-guest-hidden.md)
- [TC-650](../Test-Case/TC-650-recommended-follow-action.md)

## Notes
- Simple MVP algorithm: category overlap + activity
- More advanced recommendations in future phases
