---
name: tech-debt
model: claude-sonnet-4-0
description: Technical debt analysis and remediation. Scans codebase for code smells, duplication, complexity, testing gaps, and architecture issues. Generates prioritized reports with ROI estimates. Use /tech-debt to run full analysis or /tech-debt [area] for targeted scan.
argument-hint: "[area] e.g. challenges, goals, all"
---

# Technical Debt Analysis and Remediation

Analyze the HeadsUp codebase to identify, quantify, and prioritize technical debt. Generate actionable remediation plans with clear ROI.

**Target:** $ARGUMENTS

---

## Workflow

### Phase 1: Scan & Inventory

Conduct a thorough scan based on the target area. If no area specified, scan the full codebase.

**Target Mapping:**

| Argument | Scan Scope |
|----------|-----------|
| `all` | Full codebase |
| `challenges` | `lib/heads_up/challenges*`, `lib/heads_up_web/live/challenge_live/*` |
| `goals` | `lib/heads_up/goals*`, `lib/heads_up_web/live/goal_live/*` |
| `users` | `lib/heads_up/accounts*`, `lib/heads_up_web/live/users_live/*` |
| `social` | Social features: likes, comments, subscriptions, feed |
| `admin` | `lib/heads_up_web/live/admin_live/*` |
| `tests` | `test/**/*_test.exs` |
| `schemas` | `lib/heads_up/**/*.ex` (Ecto schemas only) |
| `liveviews` | `lib/heads_up_web/live/**/*.ex` |

#### 1.1 Code Debt Scan

Search for these patterns:

**Duplicated Code**
- Grep for identical function bodies across files
- Look for repeated query patterns in contexts
- Find duplicated template/component markup
- Identify copy-pasted event handlers in LiveViews

**Complex Code**
- Functions longer than 50 lines
- Deeply nested `case`/`cond`/`if` blocks (>3 levels)
- LiveView `render/1` functions over 200 lines
- Context modules over 500 lines
- Functions with more than 5 parameters

**Poor Structure**
- Context functions that bypass the context pattern (direct Repo calls in LiveViews)
- Missing ownership/authorization checks
- Circular module dependencies
- Business logic in templates/components

#### 1.2 Architecture Debt Scan

- Missing context boundaries (logic in wrong context)
- Fat LiveViews (business logic in event handlers instead of contexts)
- Missing PubSub for real-time features
- Inconsistent error handling patterns
- Missing or inconsistent API boundaries

#### 1.3 Testing Debt Scan

- Files with no corresponding test file
- Context functions without test coverage
- LiveView events without test coverage
- Missing edge case tests (empty states, boundaries, errors)
- Slow or flaky tests

#### 1.4 Schema & Migration Debt

- Missing indexes on foreign keys
- Missing unique constraints
- Inconsistent timestamp types (`naive_datetime` vs `utc_datetime`)
- Missing `on_delete` specifications
- Schema fields without validation in changeset

#### 1.5 Documentation Debt

- Public context functions without `@doc`
- Missing `@moduledoc` on modules
- Undocumented complex business rules
- Missing typespec (`@spec`) on public functions

---

### Phase 2: Impact Assessment

For each debt item found, assess:

**Severity Levels:**
- **Critical**: Security risk, data integrity, production crashes
- **High**: Bugs likely, significant dev time waste, performance degradation
- **Medium**: Developer friction, maintenance burden, inconsistency
- **Low**: Code style, minor inefficiency, cosmetic

**Impact Scoring:**
```
Impact = Frequency_of_change x Severity x Blast_radius

Where:
  Frequency: How often this code is touched (1-5)
  Severity: How bad the debt is (1-5)
  Blast_radius: How much code is affected (1-5)
```

---

### Phase 3: Generate Report

Create the report at `project/tech-debt/TD-[DATE]-[area].md`

```markdown
# Technical Debt Report: [Area]
**Date:** YYYY-MM-DD
**Scope:** [what was scanned]
**Overall Score:** X/100 (lower = more debt)

## Executive Summary
- Total debt items: X
- Critical: X | High: X | Medium: X | Low: X
- Estimated remediation effort: X hours
- Top 3 priorities: [list]

## Debt Inventory

### Critical Items
| # | Category | File | Description | Impact | Effort |
|---|----------|------|-------------|--------|--------|
| 1 | [type]   | path | description | score  | hours  |

### High Priority Items
[same table format]

### Medium Priority Items
[same table format]

### Low Priority Items
[same table format]

## Metrics

### Code Quality
- Average function length: X lines
- Functions >50 lines: X
- Modules >500 lines: X
- Duplicated patterns: X locations

### Test Coverage
- Context functions tested: X%
- LiveView events tested: X%
- Files without tests: X

### Schema Health
- Missing indexes: X
- Missing validations: X
- Inconsistent patterns: X

## Quick Wins (< 4 hours each)
1. [item] - Effort: Xh, Savings: Xh/month
2. [item] - Effort: Xh, Savings: Xh/month

## Remediation Roadmap

### Week 1-2: Quick Wins
- [ ] [task]
- [ ] [task]

### Month 1: High Priority
- [ ] [task]
- [ ] [task]

### Month 2-3: Medium Priority
- [ ] [task]
- [ ] [task]

## Prevention Recommendations
1. [recommendation]
2. [recommendation]
```

---

### Phase 4: Create Tasks

For each Quick Win and High Priority item, create a task file:

**Location:** `project/tech-debt/tasks/TDT-XXX-[slug].md`

```markdown
# TDT-XXX: [Task Title]

## Source
- Report: TD-[DATE]-[area].md
- Severity: [Critical/High/Medium/Low]
- Impact Score: X/125

## Description
[What needs to change and why]

## Files Affected
- `path/to/file.ex`

## Steps
1. [step]
2. [step]
3. [step]

## Effort Estimate
- Hours: X
- Complexity: [Low/Medium/High]

## Acceptance Criteria
- [ ] [criterion]
- [ ] [criterion]
- [ ] Tests pass: `mix test`

## Status
- [ ] Planned
- [ ] In Progress
- [ ] Done
- [ ] Verified
```

---

## Elixir/Phoenix Specific Checks

### Context Pattern Violations
```elixir
# BAD: Repo call in LiveView
def handle_event("save", params, socket) do
  Repo.insert(changeset)  # Should be in context
end

# GOOD: Context function
def handle_event("save", params, socket) do
  Goals.create_goal(params)
end
```

### LiveView Anti-patterns
```elixir
# BAD: Business logic in template
<%= if length(user.goals) >= 2 do %>  # Magic number, logic in template

# GOOD: Helper or context function
<%= if Goals.at_limit?(@current_user) do %>
```

### Schema Checks
```elixir
# Check for: missing validates, missing indexes, missing on_delete
schema "goals" do
  belongs_to :user, User  # Should have on_delete
  field :status, Ecto.Enum  # Should validate in changeset
end
```

### Query Performance
```elixir
# BAD: N+1 query
goals |> Enum.map(fn g -> Repo.preload(g, :user) end)

# GOOD: Batch preload
goals |> Repo.preload(:user)
```

---

## Output

After generating the report, display a summary:

```
Tech Debt Analysis Complete
============================
Scope: [area]
Report: project/tech-debt/TD-[DATE]-[area].md
Tasks: X created in project/tech-debt/tasks/

Summary:
  Critical: X items
  High:     X items
  Medium:   X items
  Low:      X items
  Total:    X items

Top 3 Quick Wins:
  1. [description] (Xh effort, Xh/month savings)
  2. [description] (Xh effort, Xh/month savings)
  3. [description] (Xh effort, Xh/month savings)

Estimated total remediation: X hours
```
