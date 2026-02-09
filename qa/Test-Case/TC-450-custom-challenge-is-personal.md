# TC-450: Custom Challenge Created by User is a Personal Challenge

## Linked User Story
- [US-402](../USER-STORY/US-402-create-custom-challenge.md)

## Test Type
Context / Unit

## Priority
Critical (regression test for BUG-1)

## Preconditions
- Registered user exists
- User is logged in

## Test Steps
1. User creates a custom challenge via `Challenges.create_challenge/2`
2. Verify challenge has `is_template=false`
3. Verify user is auto-joined as a participant
4. Verify participant status is `:active`

## Expected Results
- Challenge `is_template` is `false`
- A `ChallengeParticipant` record exists for the creator
- Participant status is `:active`
- Challenge is usable as a personal challenge (check-in, feed, progress)

## Test Data
| Field | Value |
|-------|-------|
| title | "My Test Challenge" |
| type | :custom |
| start_date | today |
| end_date | today + 30 |

## Edge Cases
- User creates custom challenge with tasks — still personal, still auto-joined
- Admin creates custom challenge — should also be personal (not template)

## Bug Reference
- BUGS/BUG-1.md

## Automation Status
- [x] Automated in: `test/heads_up/challenges_test.exs` (describe "BUG-1 regression")
