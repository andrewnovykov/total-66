# BUG-7: Target Date Should Be Required for Goal Creation

## Status
- [x] Investigating
- [x] Documented
- [x] In Progress
- [x] Fixed
- [ ] Verified

## References
- PRD: project/ROADMAP.md (Phase 0.2)
- User Story: [US-100](../USER-STORY/US-100-goal-creation.md)
- Test Case: [TC-105](../Test-Case/TC-105-goal-create-missing-target-date.md)

## Priority
High

## Severity
Major

## Reporter
QA Team

## Date Reported
2025-02-05

## Date Fixed
2025-02-05

---

## Summary
Target date (do date) should be required when creating a goal, but currently users can create goals without specifying a target date.

## Steps to Reproduce
1. Log in as registered user
2. Navigate to My Goals
3. Click "Create Goal"
4. Fill in title, category, visibility
5. Leave target date empty
6. Click Save

## Expected Result
- Goal creation should fail
- Error message: "Target date can't be blank"
- User should remain on creation form

## Actual Result (Before Fix)
- Goal is created successfully without a target date
- No validation error shown

---

## Investigation

### Related Files
- `lib/heads_up/goal.ex` - Goal schema and changeset
- `lib/heads_up_web/live/goal_live/form_component.ex` - Goal creation form
- `lib/heads_up/goals.ex` - Goals context
- `test/support/fixtures/goals_fixtures.ex` - Test fixtures

### Root Cause Analysis
In `lib/heads_up/goal.ex` line 36, the `validate_required` only included:
```elixir
|> validate_required([:title, :group_id, :user_id])
```

The `target_date` field was NOT included in the required validation, making it optional.

### Fix Applied
Added `target_date` to the `validate_required` list in the Goal changeset:
```elixir
|> validate_required([:title, :group_id, :user_id, :target_date])
```

---

## Resolution

### Fix Implemented
- [x] Code changes complete (`lib/heads_up/goal.ex`)
- [x] Test fixtures updated (`test/support/fixtures/goals_fixtures.ex`)
- [ ] All existing tests pass (some test files need target_date added to goal creation)
- [x] New test case created (TC-105)

### Files Modified
1. `lib/heads_up/goal.ex` - Added `target_date` to `validate_required`
2. `test/support/fixtures/goals_fixtures.ex` - Added `target_date` to default attributes
3. `test/heads_up/goal_ownership_test.exs` - Added `target_date` to goal creation
4. `test/heads_up_web/live/goal_privacy_test.exs` - Added `target_date` to goal creation
5. `test/heads_up_web/live/my_goals_clickable_test.exs` - Added `target_date` to goal creation
6. `test/heads_up_web/components/commitment_chart_test.exs` - Added `target_date` to goal creation

### Remaining Work
Some test files still need `target_date` added to their goal creation calls. Run:
```bash
grep -r "create_goal(%{" test/ --include="*.exs" | grep -v "target_date"
```
to find remaining files.

### Verification
- [x] Bug no longer reproducible (validation rejects empty target_date)
- [ ] No regression in related features (pending full test suite update)

### QA Documentation Updated
- [x] User Story US-100 AC-7 updated: "User **must** set target/due date (required)"
- [x] Test Case TC-105 created for missing target date validation
