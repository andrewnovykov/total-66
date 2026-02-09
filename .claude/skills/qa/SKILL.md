---
name: qa
description: Generate user stories and test cases from project documentation. Reads project/ and project_doc/ folders, creates qa/USER-STORY/ and qa/Test-Case/ files with bidirectional linking. Use /qa to generate all, or /qa [feature] for specific feature.
argument-hint: "[feature-name] (optional)"
---

# QA Documentation Generator

Generate comprehensive user stories and test cases from project requirements.

**Feature Filter:** $ARGUMENTS (empty = generate all)

## Source Directories

Read and analyze these directories for requirements:

```
project/
├── ROADMAP.md              # Phase definitions and features
├── sprint-*/PRD-*.md       # Product requirements docs
├── to-do.md                # Implementation notes
└── notes.md                # Development notes

project_doc/
├── docs/requirements/      # Feature requirements
├── docs/specifications/    # Technical specs
├── docs/design/pages/      # Page designs
└── docs/guides/            # Implementation guides
```

## Output Structure

```
qa/
├── USER-STORY/
│   ├── US-001-user-registration.md
│   ├── US-002-goal-creation.md
│   ├── US-003-goal-steps.md
│   └── ...
└── Test-Case/
    ├── TC-001-registration-valid-user.md
    ├── TC-002-registration-duplicate-email.md
    ├── TC-003-goal-create-success.md
    └── ...
```

## Workflow

### Step 1: Analyze Requirements

1. Read `project/ROADMAP.md` for all phases and features
2. Scan `project/sprint-*/PRD-*.md` for detailed requirements
3. Read `project_doc/docs/requirements/` for feature specs
4. Read `project_doc/docs/specifications/` for technical details
5. Extract all user-facing features and behaviors

### Step 2: Generate User Stories

For each feature, create a user story file in `qa/USER-STORY/`:

**File naming:** `US-[number]-[feature-slug].md`

**Template:**
```markdown
# US-[number]: [Title]

## User Story
As a [user type],
I want to [action/goal],
So that [benefit/value].

## Acceptance Criteria
- [ ] AC-1: [Criterion 1]
- [ ] AC-2: [Criterion 2]
- [ ] AC-3: [Criterion 3]

## User Types
- Guest / Registered User / Admin

## Priority
High / Medium / Low

## Source
- PRD: project/sprint-X/PRD-Y.md
- Requirement: project_doc/docs/requirements/[file].md

## Linked Test Cases
- [TC-XXX](../Test-Case/TC-XXX-description.md)
- [TC-YYY](../Test-Case/TC-YYY-description.md)

## Notes
Additional context or edge cases.
```

### Step 3: Generate Test Cases

For each acceptance criterion and edge case, create test case files in `qa/Test-Case/`:

**File naming:** `TC-[number]-[test-slug].md`

**Template:**
```markdown
# TC-[number]: [Test Title]

## Linked User Story
- [US-XXX](../USER-STORY/US-XXX-feature.md)

## Test Type
Unit / Integration / E2E / LiveView

## Priority
Critical / High / Medium / Low

## Preconditions
- [Required state or setup]
- [User must be logged in as X]

## Test Steps
1. [Action 1]
2. [Action 2]
3. [Action 3]

## Expected Results
- [Expected outcome 1]
- [Expected outcome 2]

## Test Data
| Field | Value |
|-------|-------|
| email | test@example.com |
| password | SecurePass123! |

## Edge Cases
- [Edge case 1]
- [Edge case 2]

## Automation Status
- [ ] Automated in: `test/path/to/test.exs`
```

## Feature Categories

Generate user stories and test cases for these HeadsUp features:

### User Management
- Registration (email, username validation)
- Login/Logout
- Profile management (edit, avatar, password)
- Account deletion
- User blocking (admin)

### Goal Management
- Goal creation (max 2 per user)
- Goal editing (owner only)
- Goal deletion
- Goal status (active/paused/completed/cancelled)
- Goal privacy (public/private/friends_only)
- Goal categories

### Goal Steps
- Step creation (max 20 per goal)
- Step editing
- Step completion
- Step ordering
- Step deletion

### Social Features
- Goal likes (no self-likes)
- Goal subscriptions
- Goal posts (update/milestone/achievement/challenge/motivation)
- Post comments
- User feed

### Admin Features
- User management
- Category management
- Content moderation

## Linking Rules

### User Story → Test Cases
Each user story MUST link to:
- At least 1 happy path test case
- At least 1 negative/error test case
- Edge case tests for boundary conditions

### Test Case → User Story
Every test case MUST link back to exactly one user story.

## Numbering Convention

- **US-001 to US-099**: Core user features
- **US-100 to US-199**: Goal features
- **US-200 to US-299**: Social features
- **US-300 to US-399**: Admin features

- **TC-001 to TC-099**: User feature tests
- **TC-100 to TC-199**: Goal feature tests
- **TC-200 to TC-299**: Social feature tests
- **TC-300 to TC-399**: Admin feature tests

## Commands

### `/qa`
Generate all user stories and test cases from project documentation.

### `/qa [feature]`
Generate user stories and test cases for a specific feature only.

Examples:
```bash
/qa                    # Generate all
/qa goals              # Goal-related stories and tests
/qa authentication     # Auth-related stories and tests
/qa social             # Social features stories and tests
```

### `/qa sync`
Update links between existing user stories and test cases.

### `/qa report`
Generate a coverage report showing:
- Total user stories
- Total test cases
- Stories without test cases
- Orphaned test cases
- Automation coverage percentage

## Validation

After generation, verify:
1. Every user story has at least 2 linked test cases
2. Every test case links to exactly 1 user story
3. No orphaned files exist
4. Numbering is sequential with no gaps
5. All source references are valid

## Output Summary

After completion, display:
```
QA Documentation Generated
===========================
User Stories: X created/updated
Test Cases: Y created/updated

Coverage:
- Stories with tests: X/X (100%)
- Test automation: Y/Z (XX%)

New files:
- qa/USER-STORY/US-XXX-feature.md
- qa/Test-Case/TC-XXX-test.md
...
```
