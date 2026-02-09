# TC-539: Participant Sets Visibility

## Linked User Story
- [US-510](../USER-STORY/US-510-participant-visibility.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- Participant has goal instance

## Test Steps
1. Navigate to goal instance
2. Access settings
3. Change visibility to "private"
4. Save changes

## Expected Results
- Visibility setting saved
- Applies to outside viewers
- Coach still has access

## Test Data
| Field | Value |
|-------|-------|
| visibility | private |

## Edge Cases
- Friends-only setting

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/goal_live_test.exs`
