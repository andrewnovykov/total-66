# US-603: Send Friend Request

## User Story
As a registered user,
I want to send friend requests to other users,
So that I can build a trusted network for sharing private content.

## Acceptance Criteria
- [ ] AC-1: User can send friend request from profile or people page
- [ ] AC-2: Button changes to "Request Sent" after sending
- [ ] AC-3: Cannot send request to existing friend
- [ ] AC-4: Cannot send duplicate request to same user
- [ ] AC-5: Cannot send request to yourself
- [ ] AC-6: Recipient receives notification of request
- [ ] AC-7: Guests cannot send friend requests

## User Types
- Registered User

## Priority
High

## Source
- Requirement: project_doc/docs/requirements/04-features/08-social-graph.md
- Requirement: project_doc/docs/requirements/05-business-rules.md

## Linked Test Cases
- [TC-617](../Test-Case/TC-617-friend-request-send-success.md)
- [TC-618](../Test-Case/TC-618-friend-request-button-state.md)
- [TC-619](../Test-Case/TC-619-friend-request-existing-blocked.md)
- [TC-620](../Test-Case/TC-620-friend-request-duplicate-blocked.md)
- [TC-621](../Test-Case/TC-621-friend-request-self-blocked.md)
- [TC-622](../Test-Case/TC-622-friend-request-guest-blocked.md)

## Notes
- Friends are mutual (requires accept)
- Different from one-way follow relationship
