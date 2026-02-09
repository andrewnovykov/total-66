# TC-528: Detailed Participant Progress

## Linked User Story
- [US-507](../USER-STORY/US-507-participant-progress-tracking.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Coach viewing participant detail

## Test Steps
1. Navigate to participant detail
2. View progress section
3. Check completed vs pending

## Expected Results
- Progress percentage displayed
- Completed steps listed
- Pending steps shown
- Phase-by-phase breakdown

## Test Data
| Field | Value |
|-------|-------|
| completed_steps | 5 |
| pending_steps | 15 |
| progress | 25% |

## Edge Cases
- Skipped steps

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/participant_live_test.exs`
