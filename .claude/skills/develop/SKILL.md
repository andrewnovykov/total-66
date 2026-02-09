---
name: develop
description: End-to-end PRD development workflow. Takes a PRD path and orchestrates planning (headsup-planner), implementation (headsup-implementer), and testing (headsup-tester) phases. Use with /develop project/sprint-X/PRD-Y.md
argument-hint: project/sprint-X/PRD-Y.md
---

# HeadsUp Development Workflow

Implement a complete feature from PRD to tested code.

**PRD Path:** $ARGUMENTS

## Workflow

Execute these 3 phases in sequence:

### Phase 1: Planning (headsup-planner agent)

Use the `headsup-planner` agent to:
1. Read the PRD file at `$ARGUMENTS`
2. Load TRD references from PRD header
3. Read project/ROADMAP.md for phase context
4. Analyze existing codebase patterns
5. Create implementation plan with:
   - Files to create/modify
   - Implementation order
   - Dependencies and edge cases

**Output:** Implementation plan with file list and order

### Phase 2: Implementation (headsup-implementer agent)

Use the `headsup-implementer` agent to:
1. Follow the plan from Phase 1
2. Implement in order:
   - Database migration (if needed)
   - Schema with changesets
   - Context functions with ownership validation
   - LiveView/LiveComponent
   - Router updates
3. Run `mix ecto.migrate` and `mix compile`
4. Check off completed tasks in the PRD

**HeadsUp Rules:**
- Goals: max 2 per user
- Steps: max 20 per goal
- Privacy: public/private/friends_only
- No self-likes
- Use `timestamps(type: :utc_datetime)`
- Add indexes in migrations

**Output:** Working feature, all PRD tasks checked

### Phase 3: Testing (headsup-tester agent)

Use the `headsup-tester` agent to:
1. Create required test types:
   - Unit tests (`test/heads_up/[feature]_test.exs`)
   - LiveView tests (`test/heads_up_web/live/[feature]_live_test.exs`)
   - User flow tests (`test/heads_up_web/flows/[feature]_flow_test.exs`)
   - API tests (if applicable)
2. Run `mix test` - fix any failures
3. Ensure 100% feature coverage

**Output:** All tests passing

## Completion

After all phases:
1. Update PRD State: `DONE`
2. Set Completed Date: `YYYY-MM-DD`
3. Run final checks:
   ```bash
   mix compile --warnings-as-errors
   mix test
   mix format --check-formatted
   ```
4. Report next PRD from header
