# Feature 12: Business Rule — 3 Active Items Maximum

## User Story
“As the platform, I want to limit users to 3 active items so they stay focused and don’t create vanity goals.”

## Rule
A user cannot have more than 3 active items simultaneously, counting:
- Active Goals
- Active Challenges (predefined or user-created)
- Active Group Goal instances (participant goals created from coach template)

## Enforced On
- Creation
- Reactivation (Frozen → Active)
- Joining a challenge/group goal if it auto-activates

## UX Output
“Create” disabled + message:
“You already have 3 active goals/challenges. Freeze or complete one to start another.”
