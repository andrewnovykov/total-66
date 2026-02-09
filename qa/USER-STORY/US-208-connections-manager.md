# US-208: Connections Manager

## User Story
As a registered user,
I want a central page to manage all my social connections,
So that I can easily view and manage followers, following, friends, and friend requests in one place.

## Acceptance Criteria
- [ ] AC-1: User can access /connections page when logged in
- [ ] AC-2: Stats summary shows counts for Following, Followers, Friends, Requests
- [ ] AC-3: Following tab lists all users the current user follows
- [ ] AC-4: User can unfollow from the Following tab
- [ ] AC-5: Followers tab lists all users following the current user
- [ ] AC-6: User can remove a follower from the Followers tab
- [ ] AC-7: Friends tab lists all mutual friendships
- [ ] AC-8: User can remove a friend from the Friends tab
- [ ] AC-9: Requests tab shows incoming friend requests with Accept/Decline actions
- [ ] AC-10: Requests tab shows sent friend requests with Cancel action
- [ ] AC-11: Empty states display appropriate messages for each tab
- [ ] AC-12: Clicking stats counts switches to corresponding tab

## User Types
- Registered User
- Coach
- Admin

## Priority
High

## Source
- PRD: project/sprint-1/PRD-4.md
- Requirement: project_doc/docs/requirements/04-features/08-social-graph.md
- Design: project_doc/docs/design/pages/14-connections.md

## Linked Test Cases
- [TC-232](../Test-Case/TC-232-connections-page-access.md)
- [TC-233](../Test-Case/TC-233-connections-following-tab.md)
- [TC-234](../Test-Case/TC-234-connections-followers-tab.md)
- [TC-235](../Test-Case/TC-235-connections-friends-tab.md)
- [TC-236](../Test-Case/TC-236-connections-requests-tab.md)
- [TC-237](../Test-Case/TC-237-connections-stats-summary.md)
- [TC-238](../Test-Case/TC-238-friend-request-cancel.md)
- [TC-239](../Test-Case/TC-239-remove-follower.md)

## Notes
- Page is private (only accessible to logged-in users for their own connections)
- All relationship changes take effect immediately
- Uses tabbed interface for organization
