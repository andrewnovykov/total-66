# PRD Template Reference

This document defines the standard PRD format for HeadsUp development.

## Complete PRD Structure

```markdown
References
- TRD: [path/to/trd.md or TBD]
- TRD IDs: [comma-separated IDs or TBD]

Status
- State: TODO | IN_PROGRESS | DONE
- Completed Date: — | YYYY-MM-DD

Next Step
- Next PRD: project/sprint-X/PRD-Y.md

---

### [Phase].[Section] [Feature Name]
[Optional: Brief description of the feature]

- [ ] Task 1
  - [ ] Subtask 1a
  - [ ] Subtask 1b
- [ ] Task 2
- [ ] Task 3

### Additional Sections (optional)
[More feature sections if PRD covers multiple related features]

### Notes
[Development notes, decisions, blockers]
```

---

## Header Fields

### References Section
```markdown
References
- TRD: project_doc/docs/specifications/auth-spec.md
- TRD IDs: AUTH-001, AUTH-002
```

- **TRD**: Path to Technical Requirements Document
- **TRD IDs**: Specific requirement identifiers
- Use `TBD` if not yet defined

### Status Section
```markdown
Status
- State: IN_PROGRESS
- Completed Date: —
```

**State Values:**
- `TODO` - PRD created, work not started
- `IN_PROGRESS` - Active development
- `DONE` - All tasks completed

**Completed Date:**
- `—` when not done
- `YYYY-MM-DD` format when done

### Next Step Section
```markdown
Next Step
- Next PRD: project/sprint-0/PRD-2.md
```

- Points to logical next PRD
- Can cross sprint boundaries
- Use `—` if no clear successor

---

## Task Format

### Basic Tasks
```markdown
- [ ] Implement user registration
- [ ] Add email validation
- [ ] Create login form
```

### Nested Subtasks
```markdown
- [ ] Implement authentication
  - [ ] Registration endpoint
  - [ ] Login endpoint
  - [ ] Logout functionality
  - [ ] Session management
```

### Completed Tasks
```markdown
- [x] Create users table migration
- [x] Define User schema
- [ ] Add password hashing
```

---

## Section Numbering

Format: `[Phase].[Section] [Name]`

Examples from ROADMAP.md:
- `0.1 Authentication & Roles`
- `0.2 Goals (Create + Detail + Feed)`
- `1.1 Goal & Post Ownership`
- `2.3 Auto-Moderation`

Match the ROADMAP.md section numbers exactly.

---

## Example PRDs

### Minimal PRD (New)
```markdown
References
- TRD: TBD
- TRD IDs: TBD

Status
- State: TODO
- Completed Date: —

Next Step
- Next PRD: project/sprint-0/PRD-3.md

---

### 0.2 Goals (Create + Detail + Feed)
- [ ] Goal creation with phases and steps
- [ ] Goal visibility: public / friends-only / private
- [ ] Goal detail page with progress and posts feed
- [ ] Goal reactions (like/dislike) and comments
- [ ] Goal subscriptions (follow goal)
```

### In-Progress PRD
```markdown
References
- TRD: project_doc/docs/specifications/auth.md
- TRD IDs: AUTH-001, AUTH-002, AUTH-003

Status
- State: IN_PROGRESS
- Completed Date: —

Next Step
- Next PRD: project/sprint-0/PRD-2.md

---

### 0.1 Authentication & Roles
- [x] Registration (email + password + username)
- [x] Login / Logout
- [ ] Role system: user / coach / admin
- [ ] Role-based navigation and route guards

### Notes
- Using phx.gen.auth as base
- Role enum: [:user, :coach, :admin]
- Coach role pending design clarification
```

### Completed PRD
```markdown
References
- TRD: project_doc/docs/specifications/auth.md
- TRD IDs: AUTH-001, AUTH-002, AUTH-003, AUTH-004

Status
- State: DONE
- Completed Date: 2025-01-15

Next Step
- Next PRD: project/sprint-0/PRD-2.md

---

### 0.1 Authentication & Roles
- [x] Registration (email + password + username)
- [x] Login / Logout
- [x] Role system: user / coach / admin
- [x] Role-based navigation and route guards

### Notes
- Completed using phx.gen.auth
- Tests in test/heads_up_web/live/user_*
- Route guards in lib/heads_up_web/plugs/
```

---

## PRD Creation Checklist

When creating a new PRD:

1. [ ] Set correct sprint folder
2. [ ] Use next sequential PRD number
3. [ ] Copy section from ROADMAP.md
4. [ ] Set State to TODO
5. [ ] Link to previous PRD's "Next Step"
6. [ ] Update previous PRD's "Next Step" if needed
7. [ ] Add TRD reference if available

---

## Cross-References

### Linking to Requirements
```markdown
References
- TRD: project_doc/docs/requirements/goals-feature.md
- Design: project_doc/docs/design/pages/goals-page.md
```

### Linking Between PRDs
```markdown
### Notes
- Depends on: project/sprint-0/PRD-1.md (auth)
- Blocks: project/sprint-0/PRD-4.md (feed)
```

### Linking to Code
```markdown
### Implementation
- Schema: lib/heads_up/goals/goal.ex
- LiveView: lib/heads_up_web/live/goal_live/
- Tests: test/heads_up/goals_test.exs
```
