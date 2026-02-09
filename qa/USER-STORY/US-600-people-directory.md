# US-600: People Directory

## User Story
As a user,
I want to browse a directory of people on the platform,
So that I can discover users to follow or add as friends.

## Acceptance Criteria
- [ ] AC-1: People page accessible at /people
- [ ] AC-2: Search people by name or nickname
- [ ] AC-3: Filter by activity level (highly active, active this week, recently joined)
- [ ] AC-4: Filter by role (All, Coach)
- [ ] AC-5: Filter by friendship status (logged-in only)
- [ ] AC-6: Sort by recommended, most active, most followed, newest
- [ ] AC-7: User cards show avatar, name, bio, level, stats
- [ ] AC-8: Pagination or load more functionality

## User Types
- Guest (view only)
- Registered User
- Coach
- Admin

## Priority
High

## Source
- Requirement: project_doc/docs/design/pages/07-people.md
- ROADMAP: Phase 0.7 - People & Social Graph

## Linked Test Cases
- [TC-600](../Test-Case/TC-600-people-page-load.md)
- [TC-601](../Test-Case/TC-601-people-search.md)
- [TC-602](../Test-Case/TC-602-people-filter-activity.md)
- [TC-603](../Test-Case/TC-603-people-filter-role.md)
- [TC-604](../Test-Case/TC-604-people-filter-friendship.md)
- [TC-605](../Test-Case/TC-605-people-sort.md)
- [TC-606](../Test-Case/TC-606-people-pagination.md)
- [TC-607](../Test-Case/TC-607-people-guest-view.md)

## Notes
- Guests can view public profiles only
- Private data must not leak via People list
- Recommendation logic based on category overlap and activity
