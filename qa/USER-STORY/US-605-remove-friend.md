# US-605: Remove Friend

## User Story
As a registered user,
I want to remove existing friends,
So that I can manage my trusted network.

## Acceptance Criteria
- [ ] AC-1: User can remove friend from profile or connections page
- [ ] AC-2: Removal is immediate
- [ ] AC-3: Both users' friend counts decrement
- [ ] AC-4: Removed friend loses access to friends-only content
- [ ] AC-5: Can send new friend request after removal
- [ ] AC-6: Confirmation dialog before removal

## User Types
- Registered User

## Priority
Medium

## Source
- Requirement: project_doc/docs/requirements/04-features/08-social-graph.md
- ROADMAP: Phase 4.3 - Privacy & Friends System

## Linked Test Cases
- [TC-628](../Test-Case/TC-628-friend-remove-success.md)
- [TC-629](../Test-Case/TC-629-friend-remove-count-update.md)
- [TC-630](../Test-Case/TC-630-friend-remove-access-revoked.md)
- [TC-631](../Test-Case/TC-631-friend-remove-confirmation.md)
- [TC-632](../Test-Case/TC-632-friend-rerequest-after-remove.md)

## Notes
- Removing friend does not notify them
- Different from blocking (can still follow/interact publicly)
