---
name: doc-update
description: Update project documentation after code changes. Analyzes git diff/PR changes and updates .ai_docs/, project/, and project_doc/ to stay in sync with the codebase. Use after completing a feature, bug fix, or any code changes that affect schemas, contexts, LiveViews, routes, design, or business rules. Triggers on /doc-update or when documentation sync is needed.
argument-hint: "[branch-or-commit] (optional, defaults to current branch diff vs main)"
---

# Documentation Update Skill

Analyze what changed in the code and update all project documentation to match.

**Target:** $ARGUMENTS (empty = diff current branch vs main)

## Workflow

### Step 1: Analyze Changes

Determine what changed:

```bash
# If argument is a branch name or empty
git diff main...HEAD --stat
git diff main...HEAD --name-only
git log main..HEAD --oneline

# If argument is a commit hash
git show <commit> --stat
```

Categorize each changed file:

| File Pattern | Category | Docs to Update |
|---|---|---|
| `lib/heads_up/*.ex` (schemas) | Schema change | `.ai_docs/4-domains/schemas.md`, `project_doc/docs/specifications/data-model.md` |
| `lib/heads_up/**/contexts` or `lib/heads_up/{goals,challenges,users}.ex` | Context change | `.ai_docs/4-domains/contexts.md`, `.ai_docs/5-style-guides/contexts.md` |
| `lib/heads_up_web/live/**` | LiveView change | `.ai_docs/4-domains/live-views.md`, `project_doc/docs/design/pages/` |
| `lib/heads_up_web/router.ex` | Route change | `.ai_docs/4-domains/routing.md` |
| `lib/heads_up_web/components/**` | Component change | `.ai_docs/4-domains/function-components.md` |
| `priv/repo/migrations/**` | Migration | `.ai_docs/4-domains/schemas.md`, `project_doc/docs/specifications/data-model.md` |
| `lib/heads_up/business_rules.ex` | Business rules | `.claude/CLAUDE.md` (Key Features section) |
| `lib/heads_up_web/controllers/**` | API change | `.ai_docs/4-domains/api.md`, `project_doc/docs/specifications/api-endpoints.md` |
| `test/**` | Test change | `.ai_docs/4-domains/testing.md` |
| `lib/heads_up_web/live/**/show.ex` with uploads | Upload feature | `project_doc/docs/design/pages/` |

### Step 2: Read Current Documentation

For each category identified in Step 1, read the corresponding doc files listed above. Understand their current state so updates are precise.

### Step 3: Update .ai_docs

Update files in `.ai_docs/` to reflect the actual codebase. See **references/ai-docs-guide.md** for what each file covers and update rules.

Priority updates:
1. **schemas.md** - Add/update schema tables, fields, associations
2. **contexts.md** - Add/update context functions and their signatures
3. **live-views.md** - Add/update LiveView modules, events, assigns
4. **routing.md** - Add/update routes
5. **1-techstack.md** - Update domain concepts if new features added

### Step 4: Update project/

Update sprint PRDs and roadmap:
1. Read `project/ROADMAP.md` - Check off completed phases/features
2. Find the relevant `project/sprint-*/PRD-*.md` - Mark tasks as done `[x]`
3. If all tasks in a PRD are done, set `State: DONE` and `Completed Date: YYYY-MM-DD`

### Step 5: Update project_doc/

Update technical specifications and design docs:
1. **data-model.md** - Update ER diagram, schema tables, field lists for new/changed schemas
2. **design/pages/*.md** - Update page descriptions if UI changed (new sections, buttons, forms)
3. **api-endpoints.md** - Update if API routes changed
4. **auth-strategy.md** - Update if auth/permissions changed
5. **user-flow.md** - Update if user flows changed

### Step 6: Update CLAUDE.md (if needed)

Only update `.claude/CLAUDE.md` for significant changes:
- New data models (add to Core Data Models section)
- New LiveView pages (add to LiveView Pages Structure)
- Changed business rules (update Key Features section)
- New environment variables or config

### Step 7: Summary Report

Display a summary:

```
Documentation Updated
=====================
Changes analyzed: X files changed

Updated docs:
- .ai_docs/4-domains/schemas.md (added Challenge schema fields)
- project/sprint-0/PRD-3.md (marked 3 tasks done)
- project_doc/docs/specifications/data-model.md (updated ER diagram)
- ...

Skipped (no relevant changes):
- .ai_docs/4-domains/api.md (no API changes)
- ...
```

## Rules

1. **Only update what changed** - Do not rewrite entire files. Use targeted edits.
2. **Preserve existing content** - Add to or modify sections, never delete unrelated content.
3. **Match existing style** - Follow the formatting and conventions already in each file.
4. **Read before write** - Always read a doc file before editing it.
5. **Be factual** - Only document what actually exists in the code, not aspirational features.
6. **No redundancy** - If something is already documented correctly, skip it.

## References

- **references/ai-docs-guide.md** - Detailed guide for what each `.ai_docs/` file covers
