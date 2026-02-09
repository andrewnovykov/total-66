# HeadsUp Sprint Workflow

This document defines the sprint lifecycle and PRD management workflow for the HeadsUp project.

## Sprint Lifecycle

### 1. Sprint Planning
- Review ROADMAP.md for phase objectives
- Identify PRDs needed for the sprint
- Create PRD files using `/sprint prd create`
- Estimate task scope and dependencies

### 2. Sprint Execution
- Work through PRDs in order (PRD-1, PRD-2, etc.)
- Update PRD state: TODO → IN_PROGRESS
- Check off completed tasks within PRDs
- Document blockers and decisions

### 3. Sprint Review
- Run `/sprint progress` to generate report
- Review completed vs planned work
- Identify carryover items for shuffle

### 4. Sprint Retrospective
- Update notes.md with learnings
- Adjust future sprint estimates
- Shuffle incomplete PRDs if needed

---

## PRD State Transitions

### TODO
**Entry:** PRD created
**Exit:** Development work begins
**Actions:**
- PRD file exists with empty checkboxes
- All tasks defined and estimated
- Dependencies identified

### IN_PROGRESS
**Entry:** First task started
**Exit:** All tasks completed OR blocked
**Actions:**
- Update state marker in PRD header
- Check boxes as tasks complete
- Add notes for blockers/decisions
- May stay in this state across sessions

### DONE
**Entry:** All checkboxes marked
**Exit:** N/A (terminal state)
**Actions:**
- Update state to DONE
- Set Completed Date
- Verify Next PRD reference
- May trigger follow-up PRDs

---

## Sprint Folder Conventions

### Directory Structure
```
project/
├── sprint-0/
│   ├── PRD-1.md    # Authentication & Roles
│   ├── PRD-2.md    # Goals CRUD
│   └── PRD-3.md    # User Profiles
├── sprint-1/
│   ├── PRD-1.md    # Goal Ownership
│   └── PRD-2.md    # Status Management
└── ...
```

### Naming Rules
1. Sprint folders: `sprint-[0-9]`
2. PRD files: `PRD-[number].md`
3. Numbers start at 1, increment sequentially
4. No gaps in numbering within sprint

---

## Phase-to-Sprint Mapping

Each sprint corresponds to a ROADMAP.md phase:

| Sprint | Phase | Timeline | Focus Area |
|--------|-------|----------|------------|
| sprint-0 | Phase 0 | 3-5 weeks | Core MVP Foundations |
| sprint-1 | Phase 1 | 2-3 weeks | Security & Ownership Controls |
| sprint-2 | Phase 2 | 2 weeks | Spam Reporting & Moderation |
| sprint-3 | Phase 3 | 2-3 weeks | Admin Dashboard |
| sprint-4 | Phase 4 | 2-3 weeks | Social Following System |
| sprint-5 | Phase 5 | 1 week | Online Status & Real-time |
| sprint-6 | Phase 6 | 3-4 weeks | Challenges System |
| sprint-7 | Phase 7 | 2-3 weeks | Gamification & Level System |
| sprint-8 | Phase 8 | 2 weeks | Activity Tracking & Analytics |
| sprint-9 | Phase 9 | 2 weeks | Mobile & Performance |

---

## PRD Numbering Strategy

### Within a Sprint
- PRD-1: First feature/capability
- PRD-2: Second feature (may depend on PRD-1)
- PRD-3: Third feature
- Continue sequentially

### Cross-Sprint References
- Next PRD field links to logical successor
- May cross sprint boundaries
- Example: `project/sprint-1/PRD-1.md`

### Shuffling Rules
1. Shuffled PRDs get new numbers in destination
2. Update all "Next PRD" references
3. Don't leave gaps (renumber if needed)
4. Document shuffle in log/

---

## Blocking Tasks

When a PRD is blocked:

1. **Keep state as IN_PROGRESS**
2. **Add blocking note:**
   ```markdown
   ### Blockers
   - [ ] Waiting for design spec from project_doc/docs/design/
   - [ ] Dependency on PRD-2 authentication
   ```
3. **Document in notes.md**
4. **Consider shuffle if prolonged**

---

## Quality Gates

Before marking PRD as DONE:

1. **All tasks checked** - Every `- [ ]` is now `- [x]`
2. **Tests written** - Unit and integration tests exist
3. **Code reviewed** - Changes approved
4. **Documentation updated** - CLAUDE.md if architecture changed
5. **No critical bugs** - Basic functionality verified

---

## Daily Workflow

### Start of Day
1. Run `/sprint state` to see overview
2. Run `/sprint [current]` for focus
3. Identify today's target tasks

### During Development
1. Check off tasks as completed
2. Note blockers immediately
3. Update IN_PROGRESS state if just starting PRD

### End of Day
1. Commit PRD state changes
2. Update notes.md with progress
3. Flag any carryover items

---

## Sprint Velocity Tracking

Track in progress.md:

```markdown
## Velocity History
| Sprint | Planned PRDs | Completed | Velocity |
|--------|-------------|-----------|----------|
| sprint-0 | 9 | 7 | 78% |
| sprint-1 | 3 | 3 | 100% |
```

Use velocity to:
- Estimate future sprint capacity
- Identify process improvements
- Justify shuffle decisions
