# US-601: Follow User

## User Story
As a registered user,
I want to follow other users,
So that I can see their public activity in my feed without requiring approval.

## Acceptance Criteria
- [ ] AC-1: User can follow another user with one click
- [ ] AC-2: Follow is one-way (no approval needed)
- [ ] AC-3: Follower count updates immediately
- [ ] AC-4: Following count updates on own profile
- [ ] AC-5: Follow button changes to "Following" state
- [ ] AC-6: Cannot follow yourself
- [ ] AC-7: Guests cannot follow (shown "Sign in to follow")

## User Types
- Registered User

## Priority
High

## Source
- Requirement: project_doc/docs/requirements/04-features/08-social-graph.md
- ROADMAP: Phase 4.1 - User Following

## Linked Test Cases
- [TC-608](../Test-Case/TC-608-follow-user-success.md)
- [TC-609](../Test-Case/TC-609-follow-instant-count.md)
- [TC-610](../Test-Case/TC-610-follow-self-blocked.md)
- [TC-611](../Test-Case/TC-611-follow-guest-blocked.md)
- [TC-612](../Test-Case/TC-612-follow-button-state.md)

## Notes
- Follow is different from friendship (one-way vs mutual)
- Following a user shows their public activity in your feed
