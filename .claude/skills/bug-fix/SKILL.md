---
name: bug-fix
description: End-to-end bug fix workflow. Takes a bug file path, enriches it with user stories and test cases, implements the fix, and adds tests. Use with /bug-fix BUGS/BUG-X.md
argument-hint: BUGS/BUG-X.md
---

# Bug Fix Workflow

Complete bug resolution from investigation to tested fix.

**Bug File:** $ARGUMENTS

---

## Workflow Overview

Execute these 4 phases in sequence:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Investigation  │ -> │  Documentation  │ -> │ Implementation  │ -> │    Testing      │
│                 │    │                 │    │                 │    │                 │
│ - Read bug file │    │ - Create US/TC  │    │ - Fix the bug   │    │ - Add tests     │
│ - Find related  │    │ - Enrich bug    │    │ - Run tests     │    │ - Verify fix    │
│   US and TC     │    │   documentation │    │ - Verify fix    │    │ - Update status │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## Phase 1: Investigation

### Step 1.1: Read Bug File

Read the bug file at `$ARGUMENTS` and extract:

**From simple format:**
```
BUG FIX XX
References: PRD link
TITLE: Description
STEPS: User flow
EXPECTED RESULT: What should happen
CURRENT: What actually happens
```

**From enriched format:**
- Status, Priority, References
- Steps to Reproduce
- Expected vs Actual behavior
- Any linked user stories or test cases

### Step 1.2: Identify Affected Feature

Map bug to feature category:

| Keywords | Feature | US Range | TC Range |
|----------|---------|----------|----------|
| register, login, auth, password | User/Auth | US-001-099 | TC-001-099 |
| goal, step, progress | Goals | US-100-199 | TC-100-199 |
| like, comment, post, subscribe, feed | Social | US-200-299 | TC-200-299 |
| admin, category, moderate | Admin | US-300-399 | TC-300-399 |
| challenge, task, daily | Challenges | US-400-499 | TC-400-499 |
| coach, group goal, participant | Coach Center | US-500-599 | TC-500-599 |
| follow, friend, people, connection | Connections | US-600-699 | TC-600-699 |

### Step 1.3: Search Existing QA Documentation

```bash
# Search by feature keyword
grep -ri "[keyword]" qa/USER-STORY/
grep -ri "[keyword]" qa/Test-Case/

# Search by PRD reference
grep -ri "PRD-X" qa/USER-STORY/
```

### Step 1.4: Gap Analysis

Checklist:
- [ ] Related User Story exists? → Note: US-XXX
- [ ] Related User Story missing? → Flag for Phase 2
- [ ] Related Test Case exists? → Note: TC-XXX
- [ ] Related Test Case missing? → Flag for Phase 2

---

## Phase 2: Documentation

### Step 2.1: Create Missing User Story (if needed)

If no user story covers this bug's feature, use `headsup-planner` agent or create:

**Location:** `qa/USER-STORY/US-XXX-[feature-slug].md`

```markdown
# US-XXX: [Feature Title]

## User Story
As a [user type],
I want to [action related to bug],
So that [expected benefit].

## Acceptance Criteria
- [ ] AC-1: [Criterion that bug violates]
- [ ] AC-2: [Additional criteria]

## User Types
- [Affected user type]

## Priority
High (bug-related)

## Source
- Bug: BUGS/BUG-X.md
- PRD: [from bug references]

## Linked Test Cases
- [TC-XXX](../Test-Case/TC-XXX-description.md)

## Notes
Created during bug investigation for BUG-X.
```

### Step 2.2: Create Missing Test Case (if needed)

If no test case covers the bug scenario, create:

**Location:** `qa/Test-Case/TC-XXX-[test-slug].md`

```markdown
# TC-XXX: [Test Title - Bug Scenario]

## Linked User Story
- [US-XXX](../USER-STORY/US-XXX-feature.md)

## Test Type
E2E / LiveView

## Priority
Critical (regression test for BUG-X)

## Preconditions
- [Setup from bug reproduction steps]

## Test Steps
1. [Step from bug report]
2. [Step from bug report]
3. [Observe result]

## Expected Results
- [Expected behavior - NOT the bug behavior]

## Test Data
| Field | Value |
|-------|-------|
| [field] | [value from bug] |

## Edge Cases
- [Related edge case]

## Bug Reference
- BUGS/BUG-X.md

## Automation Status
- [ ] Automated in: `test/[path]/[file]_test.exs`
```

### Step 2.3: Enrich Bug File

Update the bug file with investigation results:

```markdown
# BUG-X: [Title from bug]

## Status
- [x] Investigating
- [x] Documented
- [ ] In Progress
- [ ] Fixed
- [ ] Verified

## References
- PRD: [original PRD]
- User Story: [US-XXX](qa/USER-STORY/US-XXX.md)
- Test Case: [TC-XXX](qa/Test-Case/TC-XXX.md)

## Priority
[Determined priority]

---

## Summary
[Original TITLE]

## Steps to Reproduce
[Original STEPS formatted]

## Expected Result
[Original EXPECTED RESULT]

## Actual Result
[Original CURRENT]

---

## Investigation

### Related Files
- `lib/heads_up/[context].ex`
- `lib/heads_up_web/live/[feature]_live.ex`
- `lib/heads_up_web/controllers/[controller].ex`

### Root Cause Analysis
[Analysis of why the bug occurs - fill after code investigation]

### Proposed Fix
[Description of fix approach]
```

---

## Phase 3: Implementation

Use the `headsup-implementer` agent to fix the bug.

### 3.1: Locate Affected Code

Based on feature type:

| Feature | Context | LiveView | Controller |
|---------|---------|----------|------------|
| Auth | `accounts.ex` | `user_*_live.ex` | `user_session_controller.ex` |
| Goals | `goals.ex` | `goal_live/*` | - |
| Social | `social.ex` | `feed_live.ex`, `post_live.ex` | - |
| Challenges | `challenges.ex` | `challenge_live/*` | - |
| Coach | `coaching.ex` | `coach_center_live/*` | - |
| Connections | `connections.ex` | `people_live.ex`, `profile_live.ex` | - |

### 3.2: Implement Fix

Follow HeadsUp conventions:
- Add ownership validation if missing
- Add proper error handling
- Use changesets for validation
- Use PubSub for real-time updates if needed
- Use `timestamps(type: :utc_datetime)` in migrations

### 3.3: Verify Fix

```bash
# Compile without warnings
mix compile --warnings-as-errors

# Run existing tests
mix test

# Manual verification
# Follow bug reproduction steps
# Confirm expected behavior now occurs
```

### 3.4: Update Bug Status

```markdown
## Status
- [x] Investigating
- [x] Documented
- [x] In Progress
- [ ] Fixed
- [ ] Verified
```

---

## Phase 4: Testing

Use the `headsup-tester` agent to add regression tests.

### 4.1: Create Regression Test

Add test that reproduces the bug scenario:

```elixir
# test/heads_up/[context]_test.exs or
# test/heads_up_web/live/[feature]_live_test.exs

describe "BUG-X regression: [brief description]" do
  test "verifies fix for: [bug title]" do
    # Setup - create conditions from bug report
    user = user_fixture()

    # Action - perform steps that triggered bug
    {:ok, result} = Context.action(user, params)

    # Assert - verify expected behavior (not the bug)
    assert result.field == expected_value
  end
end
```

### 4.2: Add Edge Case Tests

```elixir
test "edge case: [related scenario]" do
  # Test boundary conditions
end

test "prevents regression: [specific condition]" do
  # Ensure bug cannot recur
end
```

### 4.3: Run All Tests

```bash
# Run specific test file
mix test test/heads_up/[context]_test.exs

# Run all tests
mix test

# Run with coverage
mix test --cover
```

### 4.4: Update Test Case Automation Status

In the related TC-XXX file:
```markdown
## Automation Status
- [x] Automated in: `test/heads_up/[context]_test.exs`
```

---

## Phase 5: Completion

### 5.1: Final Bug Status Update

```markdown
## Status
- [x] Investigating
- [x] Documented
- [x] In Progress
- [x] Fixed
- [x] Verified

## Resolution
- **Fixed Date:** YYYY-MM-DD
- **Tests Added:** X new tests
- **Files Modified:** [list]
```

### 5.2: Final Checks

```bash
mix compile --warnings-as-errors
mix test
mix format --check-formatted
```

---

## Output Summary

After completion, display:

```
Bug Fix Complete
================
Bug: BUG-X - [Title]

Phase 1 - Investigation:
✓ Feature identified: [feature name]
✓ Affected files located

Phase 2 - Documentation:
✓ User Story: US-XXX (existing | created)
✓ Test Case: TC-XXX (existing | created)
✓ Bug file enriched

Phase 3 - Implementation:
✓ Root cause: [brief description]
✓ Fix applied to: [files]
✓ Existing tests: Passing

Phase 4 - Testing:
✓ Regression tests: X added
✓ All tests: Passing

Status: VERIFIED
```

---

## Quick Reference

### Commands

| Command | Description |
|---------|-------------|
| `/bug-fix BUGS/BUG-X.md` | Full workflow |
| `/bug-fix BUGS/BUG-X.md --investigate` | Phase 1-2 only |
| `/bug-fix BUGS/BUG-X.md --fix` | Phase 3-4 only (assumes documented) |

### Feature → QA Mapping

| Feature | User Stories | Test Cases |
|---------|--------------|------------|
| User/Auth | US-001-099 | TC-001-099 |
| Goals | US-100-199 | TC-100-199 |
| Social | US-200-299 | TC-200-299 |
| Admin | US-300-399 | TC-300-399 |
| Challenges | US-400-499 | TC-400-499 |
| Coach Center | US-500-599 | TC-500-599 |
| Connections | US-600-699 | TC-600-699 |
