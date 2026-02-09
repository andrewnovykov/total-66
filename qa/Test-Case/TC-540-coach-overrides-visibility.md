# TC-540: Coach Sees Despite Visibility

## Linked User Story
- [US-510](../USER-STORY/US-510-participant-visibility.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Participant has private goal instance
- Coach is logged in

## Test Steps
1. Navigate to participant detail
2. View progress despite private setting

## Expected Results
- Coach can see full progress
- Visibility doesn't block coach
- Coach context override works

## Test Data
| Field | Value |
|-------|-------|
| participant_visibility | private |
| coach_access | full |

## Edge Cases
- Coach views from different context

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/participant_live_test.exs`
