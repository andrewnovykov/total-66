# TC-529: Participant Commitment Heatmap

## Linked User Story
- [US-507](../USER-STORY/US-507-participant-progress-tracking.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- Coach viewing participant detail
- Participant has history

## Test Steps
1. Navigate to participant detail
2. View heatmap section
3. Check activity visualization

## Expected Results
- GitHub-style heatmap displayed
- Days colored by activity level
- Hover shows activity count
- Patterns visible

## Test Data
| Field | Value |
|-------|-------|
| activity_days | 20 |

## Edge Cases
- New participant (sparse data)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/coach/participant_live_test.exs`
