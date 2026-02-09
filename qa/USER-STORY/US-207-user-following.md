# US-207: User Following

## User Story
As a registered user,
I want to follow other users,
So that I can see their public activity in my feed.

## Acceptance Criteria
- [ ] AC-1: User can follow another user
- [ ] AC-2: User can unfollow a user
- [ ] AC-3: Following is one-way (no approval needed)
- [ ] AC-4: Follower count displayed on profile
- [ ] AC-5: Following count displayed on profile
- [ ] AC-6: Followed user's public activity appears in feed
- [ ] AC-7: User can remove a follower
- [ ] AC-8: Cannot follow private users
- [ ] AC-9: Cannot follow friends-only users (unless friends)
- [ ] AC-10: Cannot follow yourself

## User Types
- Registered User

## Priority
Medium

## Source
- PRD: project/ROADMAP.md (Phase 4.1)
- Requirement: project_doc/docs/requirements/04-features/08-social-graph.md

## Linked Test Cases
- [TC-229](../Test-Case/TC-229-follow-user.md)
- [TC-230](../Test-Case/TC-230-unfollow-user.md)
- [TC-231](../Test-Case/TC-231-follow-counts.md)
- [TC-239](../Test-Case/TC-239-remove-follower.md)
- [TC-240](../Test-Case/TC-240-follow-private-user-denied.md)
- [TC-241](../Test-Case/TC-241-follow-friends-only-user.md)
- [TC-242](../Test-Case/TC-242-self-follow-denied.md)

## Notes
- Follow is different from friendship (one-way vs mutual)
