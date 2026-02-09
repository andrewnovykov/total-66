# US-604: Respond to Friend Request

## User Story
As a registered user,
I want to accept or decline friend requests,
So that I can control who has access to my friends-only content.

## Acceptance Criteria
- [ ] AC-1: User can view pending friend requests
- [ ] AC-2: User can accept friend request
- [ ] AC-3: Accepting creates mutual friendship
- [ ] AC-4: User can decline friend request
- [ ] AC-5: Declining removes request without notification
- [ ] AC-6: Both users' friend counts update on accept
- [ ] AC-7: Accept/Decline buttons shown on pending requests

## User Types
- Registered User

## Priority
High

## Source
- Requirement: project_doc/docs/requirements/04-features/08-social-graph.md
- ROADMAP: Phase 4.3 - Privacy & Friends System

## Linked Test Cases
- [TC-623](../Test-Case/TC-623-friend-request-view-pending.md)
- [TC-624](../Test-Case/TC-624-friend-request-accept.md)
- [TC-625](../Test-Case/TC-625-friend-request-decline.md)
- [TC-626](../Test-Case/TC-626-friend-mutual-after-accept.md)
- [TC-627](../Test-Case/TC-627-friend-count-update.md)

## Notes
- Friendship is mutual (two-way relationship)
- Declining does not block future requests
