# US-200: Goal Likes

## User Story
As a registered user,
I want to like goals I find inspiring,
So that I can show support and save them for later.

## Acceptance Criteria
- [ ] AC-1: User can like a public goal
- [ ] AC-2: User cannot like their own goal
- [ ] AC-3: Like/dislike is a toggle (not both at once)
- [ ] AC-4: Like count is displayed on goal
- [ ] AC-5: User can unlike a previously liked goal
- [ ] AC-6: Guests cannot like goals
- [ ] AC-7: Likes work on friends-only goals for friends

## User Types
- Registered User

## Priority
Medium

## Source
- Requirement: project_doc/docs/requirements/04-features/09-social-interactions.md
- Requirement: project_doc/docs/requirements/05-business-rules.md

## Linked Test Cases
- [TC-200](../Test-Case/TC-200-goal-like-success.md)
- [TC-201](../Test-Case/TC-201-goal-like-self-denied.md)
- [TC-202](../Test-Case/TC-202-goal-unlike.md)
- [TC-203](../Test-Case/TC-203-goal-like-guest-denied.md)

## Notes
- Toggle behavior: like removes dislike and vice versa
