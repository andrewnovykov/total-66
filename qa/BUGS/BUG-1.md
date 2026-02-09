# BUG-1: User-created custom challenges behave as templates instead of personal challenges

## Status
- [x] Investigating
- [x] Documented
- [x] In Progress
- [x] Fixed
- [x] Verified

## References
- User Story: [US-402](../USER-STORY/US-402-create-custom-challenge.md)
- Test Case: [TC-450](../Test-Case/TC-450-custom-challenge-is-personal.md)

## Priority
Critical

---

## Summary
When a regular user creates a custom challenge via `/challenges/new`, the resulting challenge behaves like a template — no feed, no ability to check in daily. The challenge should be created as a personal user challenge (`is_template=false`) with the creator auto-joined as a participant.

## Steps to Reproduce
1. Log in as a regular user
2. Navigate to `/challenges/new`
3. Fill in challenge details (title, description, tasks, dates)
4. Submit the form
5. Navigate to the created challenge (e.g. `/challenges/16`)

## Expected Result
- Challenge is created with `is_template=false`
- Creator is automatically joined as a participant
- Show page displays daily check-in UI, feed, and progress tracking
- Challenge functions as a personal challenge the user can interact with

## Actual Result
- Challenge is created but `is_template` is not explicitly set to `false`
- Creator is NOT joined as a participant
- Show page treats it as a template — shows "Start Challenge" button instead of check-in UI
- No feed, no daily tasks, no progress tracking available

---

## Investigation

### Related Files
- `lib/heads_up/challenges.ex` — `create_challenge/2` (lines 146-184)
- `lib/heads_up_web/live/challenge_live/new.ex` — `do_create_challenge/4` (lines 365-388)
- `lib/heads_up_web/live/challenge_live/show.ex` — template vs personal UI logic (lines 24-43)

### Root Cause Analysis
Two bugs:

1. **`create_challenge/2`** (challenges.ex:160-166): For non-admin users creating custom challenges, `is_template` is never explicitly set to `false`. The code only sets `is_template=true` for admin-created predefined challenges; for all other cases it leaves `attrs` unchanged, relying on the schema default. This is fragile — if any form data or upstream logic includes an `is_template` value, it overrides the default.

2. **`do_create_challenge/4`** (new.ex:365-388): After creating a custom challenge, the user is never auto-joined as a participant. The `start_challenge_from_template/3` function correctly calls `join_challenge`, but direct creation via the form does not. Without a participant record, the show page cannot render check-in UI, daily tasks, or feed — even if `is_template` is correctly `false`.

### Proposed Fix
1. In `create_challenge/2`: Explicitly set `is_template=false` for non-admin users creating custom challenges
2. In `do_create_challenge/4`: After creating a custom challenge, auto-join the creator as a participant via `Challenges.join_challenge/3`
