# US-602: Unfollow User

## User Story
As a registered user,
I want to unfollow users I previously followed,
So that I can curate my feed and connections.

## Acceptance Criteria
- [ ] AC-1: User can unfollow with one click
- [ ] AC-2: Follower count decrements immediately
- [ ] AC-3: Unfollowed user's content no longer appears in feed
- [ ] AC-4: Button changes back to "Follow" state
- [ ] AC-5: Can re-follow after unfollowing

## User Types
- Registered User

## Priority
Medium

## Source
- Requirement: project_doc/docs/requirements/04-features/08-social-graph.md
- ROADMAP: Phase 4.1 - User Following

## Linked Test Cases
- [TC-613](../Test-Case/TC-613-unfollow-user-success.md)
- [TC-614](../Test-Case/TC-614-unfollow-count-decrement.md)
- [TC-615](../Test-Case/TC-615-unfollow-feed-update.md)
- [TC-616](../Test-Case/TC-616-refollow-after-unfollow.md)

## Notes
- Unfollowing does not notify the unfollowed user
- Can re-follow at any time
