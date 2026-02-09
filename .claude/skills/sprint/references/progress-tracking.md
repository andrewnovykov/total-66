# Progress Tracking Reference

This document defines how progress is tracked and reported in the HeadsUp project.

## Progress File Location

```
project/progress.md
```

Generated/updated by `/sprint progress` command.

---

## Progress File Format

```markdown
# HeadsUp Progress Report

**Generated:** YYYY-MM-DD HH:MM
**Project Timeline:** 16-22 weeks estimated

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Total PRDs | 24 |
| Completed | 8 (33%) |
| In Progress | 4 (17%) |
| Todo | 12 (50%) |
| Current Phase | Phase 0: Core MVP |

---

## Phase Progress

| Phase | Name | Status | PRDs | Progress |
|-------|------|--------|------|----------|
| 0 | Core MVP Foundations | Active | 5/9 | 56% |
| 1 | Security & Ownership | Pending | 0/3 | 0% |
| 2 | Spam & Moderation | Pending | 0/3 | 0% |
| 3 | Admin Dashboard | Pending | 0/6 | 0% |
| 4 | Social Following | Pending | 0/4 | 0% |
| 5 | Real-time Features | Pending | 0/2 | 0% |
| 6 | Challenges System | Pending | 0/4 | 0% |
| 7 | Gamification | Pending | 0/3 | 0% |
| 8 | Activity Analytics | Pending | 0/3 | 0% |
| 9 | Mobile & Performance | Pending | 0/2 | 0% |

---

## Sprint Details

### Sprint 0 - Core MVP Foundations
| PRD | Title | State | Tasks |
|-----|-------|-------|-------|
| PRD-1 | Authentication & Roles | DONE | 4/4 |
| PRD-2 | Goals CRUD | IN_PROGRESS | 3/5 |
| PRD-3 | User Profiles | TODO | 0/4 |

### Sprint 1 - Security & Ownership
| PRD | Title | State | Tasks |
|-----|-------|-------|-------|
| PRD-1 | Goal Ownership | TODO | 0/6 |
| PRD-2 | Status Management | TODO | 0/5 |

[Continue for all sprints...]

---

## Task Statistics

### By Category
- Authentication: 8 tasks (6 done, 2 remaining)
- Goals: 15 tasks (8 done, 7 remaining)
- Social: 12 tasks (0 done, 12 remaining)
- Admin: 18 tasks (0 done, 18 remaining)

### Completion Trend
- Week 1: 12 tasks completed
- Week 2: 8 tasks completed
- Week 3: 15 tasks completed

---

## Recent Activity

| Date | Event |
|------|-------|
| 2025-01-15 | PRD-1 marked DONE (Authentication) |
| 2025-01-16 | PRD-2 started (Goals CRUD) |
| 2025-01-18 | PRD-3 created (User Profiles) |

---

## Blockers & Risks

### Active Blockers
- [ ] PRD-4: Waiting for design spec
- [ ] PRD-7: External API dependency

### Identified Risks
- Phase 0 taking longer than estimated
- Coach role requirements unclear

---

## Velocity Metrics

| Sprint | Planned | Completed | Velocity |
|--------|---------|-----------|----------|
| 0 | 9 | 5 | 56% |
| 1 | 3 | 0 | 0% |

**Average Velocity:** 56%
**Projected Completion:** [based on velocity]
```

---

## Metrics Calculation

### PRD Completion Percentage
```
completion% = (DONE PRDs / Total PRDs) * 100
```

### Phase Progress
```
phase_progress% = (DONE PRDs in phase / Total PRDs in phase) * 100
```

### Task Completion
- Count `- [x]` vs `- [ ]` in each PRD
- Nested tasks count separately

### Velocity
```
velocity% = (Completed PRDs in sprint / Planned PRDs) * 100
```

---

## Status Definitions

### Phase Status
- **Active** - Current focus, has IN_PROGRESS PRDs
- **Pending** - Not yet started, all PRDs TODO
- **Complete** - All PRDs DONE
- **Blocked** - Has blockers preventing progress

### PRD Status
- **TODO** - Not started
- **IN_PROGRESS** - Active development
- **DONE** - All tasks completed
- **BLOCKED** - Has documented blockers

---

## Activity Log Integration

Activity events stored in `project/log/`:

```
project/log/
├── 2025-01-activity.md
├── 2025-02-activity.md
└── ...
```

### Log Entry Format
```markdown
## 2025-01-15

### PRD Changes
- PRD-1 (sprint-0): TODO → IN_PROGRESS
- PRD-1 (sprint-0): IN_PROGRESS → DONE

### Tasks Completed
- [x] Registration endpoint (PRD-1)
- [x] Login form (PRD-1)
- [x] Session management (PRD-1)

### Notes
- Authentication complete, moving to goals
```

---

## Generating Progress Report

### Command
```bash
/sprint progress
```

### Steps Performed
1. Read all sprint folders
2. Parse each PRD file for:
   - State field
   - Task checkboxes
   - Section titles
3. Aggregate statistics
4. Compare to ROADMAP.md phases
5. Generate/update progress.md
6. Output summary to console

### Output Example
```
Progress Report Generated
=========================

Summary:
- 8/24 PRDs complete (33%)
- Current: Phase 0 - Core MVP

Recent Changes:
- PRD-2 now IN_PROGRESS
- 3 tasks completed since last report

Full report: project/progress.md
```

---

## Burndown Tracking

Optional burndown chart data:

```markdown
## Burndown Data

| Week | Tasks Remaining | Ideal |
|------|-----------------|-------|
| 1 | 100 | 95 |
| 2 | 88 | 85 |
| 3 | 73 | 75 |
| 4 | 65 | 65 |
```

Calculate:
- Total tasks at project start
- Ideal linear burn rate
- Actual remaining vs ideal

---

## Dashboard View

For quick status checks, `/sprint state` shows condensed version:

```
HeadsUp Development State
=========================
Phase: 0 - Core MVP (3-5 weeks)
Progress: 33% complete

Sprint 0: ████████░░ 80% (4/5 PRDs)
Sprint 1: ░░░░░░░░░░ 0% (0/3 PRDs)
Sprint 2: ░░░░░░░░░░ 0% (0/3 PRDs)

Active: PRD-2 Goals CRUD (3/5 tasks)
Next: PRD-3 User Profiles
```

Progress bar calculation:
- Each █ = 10% completion
- Based on DONE PRDs in sprint
