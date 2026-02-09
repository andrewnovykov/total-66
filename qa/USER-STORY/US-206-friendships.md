# US-206: Friendships

## User Story
As a registered user,
I want to send and manage friend requests,
So that I can build a trusted network for sharing private content.

## Acceptance Criteria
- [ ] AC-1: User can send friend request to another user
- [ ] AC-2: User can view pending friend requests
- [ ] AC-3: User can accept friend requests
- [ ] AC-4: User can decline friend requests
- [ ] AC-5: User can remove existing friends
- [ ] AC-6: Friends can view friends-only content
- [ ] AC-7: Cannot send request to existing friend
- [ ] AC-8: User can cancel sent friend request
- [ ] AC-9: Cannot send request to self

## User Types
- Registered User

## Priority
Medium

## Source
- CLAUDE.md: Friendship Schema
- Requirement: project_doc/docs/requirements/04-features/08-social-graph.md

## Linked Test Cases
- [TC-224](../Test-Case/TC-224-friend-request-send.md)
- [TC-225](../Test-Case/TC-225-friend-request-accept.md)
- [TC-226](../Test-Case/TC-226-friend-request-decline.md)
- [TC-227](../Test-Case/TC-227-friend-remove.md)
- [TC-228](../Test-Case/TC-228-friend-duplicate-request.md)
- [TC-238](../Test-Case/TC-238-friend-request-cancel.md)

## Notes
- Friendship is mutual (requires accept)
