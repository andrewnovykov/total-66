# US-204: Post Comments

## User Story
As a registered user,
I want to comment on goal posts,
So that I can provide encouragement and feedback.

## Acceptance Criteria
- [ ] AC-1: User can add comments to posts
- [ ] AC-2: Comments have text content
- [ ] AC-3: Comments show author and timestamp
- [ ] AC-4: User can delete their own comments
- [ ] AC-5: Guests cannot comment
- [ ] AC-6: Comments respect goal visibility rules

## User Types
- Registered User

## Priority
Medium

## Source
- CLAUDE.md: GoalComment Schema
- Requirement: project_doc/docs/requirements/04-features/09-social-interactions.md

## Linked Test Cases
- [TC-216](../Test-Case/TC-216-comment-create-success.md)
- [TC-217](../Test-Case/TC-217-comment-delete-own.md)
- [TC-218](../Test-Case/TC-218-comment-guest-denied.md)
- [TC-219](../Test-Case/TC-219-comment-private-goal-denied.md)

## Notes
- Comments foster community engagement
