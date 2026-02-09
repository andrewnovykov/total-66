# BUG-1: Failed Challenge Cannot Be Restarted

## Status
- [x] Investigating
- [x] Documented
- [x] In Progress
- [x] Fixed
- [x] Verified

## Resolution
- **Fixed Date:** 2026-02-06
- **Tests Added:** 4 regression tests
- **Files Modified:**
  - `lib/heads_up/business_rules.ex` — Role/subscription-aware limits (admin=unlimited, free=3, pro=10)
  - `lib/heads_up_web/live/challenge_live/show.ex` — Specific error message for active limit reached

## References
- Feature: Challenges (template restart)
- PRD: project/sprint-0/PRD-9.md (active item limit)
- User Story: US-400 (Challenge participation)
- Test Case: TC-400 (Challenge restart)

## Priority
High

---

## Summary
Admin user who failed a challenge derived from a template cannot start the challenge again from the template page. The "Start Again" button shows a date picker modal but after confirmation, only a vague "Could not start challenge" error appears.

## Steps to Reproduce
1. Log in as admin user (or any user with 3+ active goals/challenges)
2. Start a challenge from a template (e.g., template /challenges/23)
3. Fail the challenge
4. Navigate back to the template page
5. Click "Start Again" button
6. Pick a start date and confirm
7. See error: "Could not start challenge."

## Expected Result
- If user has room under the active item limit (< 3 active items): a new challenge is created and user is navigated to it
- If user is at the active limit: a clear error message says "You've reached the maximum of 3 active goals/challenges. Complete or remove one to start a new challenge."

## Actual Result
- Vague "Could not start challenge." error with no explanation
- User has no idea why they can't start the challenge

---

## Investigation

### Root Cause Analysis
Two issues:

1. **Active item limit blocks restart**: The `start_challenge_from_template/3` function checks `BusinessRules.can_create_active_item?(user_id)` which returns `{:error, :active_limit_reached}` if the user has >= 3 active goals + challenges. The admin user in dev has 5 active items (from seed data).

2. **Vague error handling**: The `confirm_start_challenge` event handler (show.ex line 202) catches all `{:error, _}` errors with a generic "Could not start challenge." message. It doesn't have a specific handler for `:active_limit_reached`.

### Related Files
- `lib/heads_up/challenges.ex` — `start_challenge_from_template/3` (line 235)
- `lib/heads_up_web/live/challenge_live/show.ex` — `confirm_start_challenge` handler (line 179)
- `lib/heads_up/business_rules.ex` — `can_create_active_item?/1`

### Proposed Fix
Add specific error handling for `:active_limit_reached` in the `confirm_start_challenge` event handler, showing a clear error message that tells the user why they can't start the challenge and what to do about it.
