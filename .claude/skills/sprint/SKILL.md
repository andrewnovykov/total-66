---
name: sprint
description: Sprint planning and progress tracking for HeadsUp development. Use when managing PRDs, checking sprint status, creating new PRDs, generating progress reports, or shuffling work between sprints. Triggers on /sprint commands.
---

# HeadsUp Planner Skill

A sprint planning and progress tracking skill for the HeadsUp project. Manages PRDs, sprint organization, and development progress using Manus context engineering principles.

## Commands

### `/sprint state`
Show current sprint and project status overview.

**Actions:**
1. Read project/ROADMAP.md to identify current phase
2. Scan all sprint folders (project/sprint-0/ through sprint-9/)
3. Count PRDs by status (TODO, IN_PROGRESS, DONE)
4. Display summary with phase context

**Output Format:**
```
HeadsUp Development State
========================
Current Phase: [Phase X - Name] ([Timeline])

Sprint Status:
- sprint-0: 3 PRDs (1 DONE, 1 IN_PROGRESS, 1 TODO)
- sprint-1: 2 PRDs (0 DONE, 0 IN_PROGRESS, 2 TODO)
...

Active Work:
- PRD-2.md: Goals CRUD (IN_PROGRESS)
- PRD-3.md: User Profiles (IN_PROGRESS)
```

---

### `/sprint [n]`
Focus on a specific sprint and load its context.

**Arguments:**
- `n` (required): Sprint number (0-9)

**Actions:**
1. Load project/sprint-[n]/ folder
2. Read all PRD files in the sprint
3. Extract state and task lists from each PRD
4. Show blocking tasks and dependencies

**Output Format:**
```
Sprint [n] Overview
==================
Phase: [Phase from ROADMAP.md]
PRDs: [count]

PRD-1.md: [Title from heading]
  State: TODO | IN_PROGRESS | DONE
  Tasks: [completed]/[total]
  Next: [Next PRD reference]

PRD-2.md: [Title]
  State: IN_PROGRESS
  Tasks: 3/7
  Blocking: "Implement role-based guards"
```

---

### `/sprint prd create [sprint] [number]`
Create a new PRD file with HeadsUp template format.

**Arguments:**
- `sprint` (required): Sprint number (0-9)
- `number` (required): PRD number within sprint

**Actions:**
1. Verify sprint folder exists (create if needed)
2. Check PRD doesn't already exist
3. Look up corresponding section from ROADMAP.md
4. Generate PRD using template format
5. Set initial state to TODO

**Template:**
```markdown
References
- TRD: TBD
- TRD IDs: TBD

Status
- State: TODO
- Completed Date: —

Next Step
- Next PRD: project/sprint-[X]/PRD-[Y].md

---

### [Phase].[Section] [Feature Name]
- [ ] Task 1
- [ ] Task 2
```

---

### `/sprint progress`
Generate or update progress summary across all sprints.

**Actions:**
1. Scan all sprint folders for PRD files
2. Parse state from each PRD
3. Calculate statistics:
   - Total PRDs by state
   - Tasks completed vs remaining
   - Phase completion percentages
4. Create/update project/progress.md

**Output Format:**
```markdown
# HeadsUp Progress Report
Generated: [timestamp]

## Summary
- Total PRDs: 24
- Completed: 8 (33%)
- In Progress: 4 (17%)
- Todo: 12 (50%)

## Phase Progress
| Phase | Status | PRDs Done | Total |
|-------|--------|-----------|-------|
| Phase 0 | Active | 3/9 | 33% |
| Phase 1 | Pending | 0/3 | 0% |
...

## Recent Activity
- [date] PRD-2.md marked DONE
- [date] PRD-5.md started (IN_PROGRESS)
```

---

### `/sprint shuffle [from-sprint] [to-sprint] [prd-number]`
Move a PRD between sprints.

**Arguments:**
- `from-sprint` (required): Source sprint number
- `to-sprint` (required): Destination sprint number
- `prd-number` (required): PRD number to move

**Actions:**
1. Verify source PRD exists
2. Determine new PRD number in destination (next available)
3. Move file to destination folder
4. Update "Next PRD" references in affected files
5. Report changes made

**Output:**
```
Shuffled PRD-3.md from sprint-1 to sprint-2
- New location: project/sprint-2/PRD-4.md
- Updated references in: PRD-2.md, PRD-4.md (old)
```

---

## Project Structure

### Source of Truth
```
project/
├── ROADMAP.md              # 10 phases with tasks
├── sprint-0/ to sprint-9/  # Sprint folders
│   └── PRD-*.md            # Product Requirements Docs
├── to-do.md                # Implementation notes
├── notes.md                # Development notes
├── progress.md             # Generated progress report
└── log/                    # Activity logs
```

### Requirements Reference
```
project_doc/
├── docs/requirements/      # Feature requirements
├── docs/specifications/    # Technical specs
├── docs/design/pages/      # Page designs
└── docs/guides/            # Implementation guides
```

---

## PRD State Machine

```
TODO ──────► IN_PROGRESS ──────► DONE
  │              │                 │
  │              │                 ▼
  │              └──────► (blocked state noted in PRD)
  │
  ▼
(can be shuffled to different sprint)
```

**State Transitions:**
- TODO → IN_PROGRESS: When work begins
- IN_PROGRESS → DONE: When all tasks checked
- Any → Blocked: Add note in PRD, remains IN_PROGRESS

---

## Phase-to-Sprint Mapping

| Sprint | Phase | Focus |
|--------|-------|-------|
| sprint-0 | Phase 0 | Core MVP Foundations |
| sprint-1 | Phase 1 | Security & Ownership |
| sprint-2 | Phase 2 | Spam & Moderation |
| sprint-3 | Phase 3 | Admin Dashboard |
| sprint-4 | Phase 4 | Social Following |
| sprint-5 | Phase 5 | Real-time Features |
| sprint-6 | Phase 6 | Challenges System |
| sprint-7 | Phase 7 | Gamification |
| sprint-8 | Phase 8 | Activity Analytics |
| sprint-9 | Phase 9 | Mobile & Performance |

---

## Context Loading Strategy

Following Manus principles for attention manipulation:

1. **State Command**: Load only ROADMAP.md + PRD headers (minimal context)
2. **Sprint Command**: Load single sprint folder + related ROADMAP phase
3. **PRD Create**: Load ROADMAP section + template reference
4. **Progress**: Scan headers only, generate summary
5. **Shuffle**: Load source PRD + destination folder listing

Never load entire codebase. Use progressive disclosure.

---

## File Conventions

### PRD Naming
- Format: `PRD-[number].md`
- Numbers are sequential within sprint
- Start at 1 for each sprint

### State Markers
- `State: TODO` - Not started
- `State: IN_PROGRESS` - Active work
- `State: DONE` - Completed
- `Completed Date: [YYYY-MM-DD]` - When marked done

### Task Format
- `- [ ]` Incomplete task
- `- [x]` Completed task
- Nested tasks allowed for subtasks

---

## Usage Examples

```bash
# Check overall project state
/sprint state

# Focus on current sprint work
/sprint 0

# Create new PRD for authentication
/sprint prd create 0 2

# Generate progress report
/sprint progress

# Move delayed PRD to later sprint
/sprint shuffle 1 3 2
```

---

## Resources

This skill includes reference documentation for detailed workflows:

### references/
- **headsup-workflow.md** - Sprint lifecycle and PRD management workflow
- **prd-template.md** - Standard PRD format and examples
- **progress-tracking.md** - Progress file format and metrics

Load these references when more detailed guidance is needed for specific operations.

---

## Integration Notes

- PRDs reference TRDs (Technical Requirements Docs) when available
- ROADMAP.md is authoritative for phase definitions
- project_doc/ contains detailed requirements for reference
- Tests should be created alongside PRD implementation
