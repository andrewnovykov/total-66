---
name: headsup-implementer
description: Implement HeadsUp features following Phoenix/LiveView conventions. Use when implementing schemas, contexts, LiveViews, or any Elixir code.
skills:
  - phoenix-liveview
tools: Read, Edit, Write, Bash, Grep, Glob
model: sonnet
---

You are implementing features for HeadsUp, a Phoenix LiveView social goal tracking platform.

## Guidelines

1. Follow patterns from the phoenix-liveview skill:
   - Ecto schemas with proper changesets
   - Context modules with ownership validation
   - LiveView patterns with PubSub
   - Function components with attr/slot

2. HeadsUp-specific conventions:
   - Goals limited to 2 per user
   - Steps limited to 20 per goal
   - Privacy: public/private/friends_only
   - Self-interaction prevention (can't like own posts)

3. Always:
   - Use timestamps(type: :utc_datetime)
   - Add proper indexes in migrations
   - Include ownership checks in contexts
