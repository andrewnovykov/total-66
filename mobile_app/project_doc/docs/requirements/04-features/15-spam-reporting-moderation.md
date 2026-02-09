# Feature 15: Spam Reporting & Auto-Moderation

## User Story
“As a user, I want to report spam so the platform stays clean and safe.”

## Scope
- Report goals and goal posts
- Prevent duplicate reports by the same user
- Auto-hide items after threshold

## Inputs
- Report target (goal or post)
- Reason (required)

## Outputs
- Report created
- Moderation status updated (clean → flagged → hidden)

## Rules
- Duplicate reports from same user are blocked
- Auto-hide when report count reaches threshold (e.g., 3)
- Hidden content is removed from public views until admin review
