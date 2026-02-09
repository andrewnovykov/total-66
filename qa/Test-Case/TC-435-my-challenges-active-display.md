# TC-435: Active Challenge Display in Dashboard

## Linked User Story
- [US-409](../USER-STORY/US-409-my-challenges-dashboard.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User has active challenge

## Test Steps
1. Navigate to My Challenges
2. View active challenge card
3. Check information displayed

## Expected Results
- Active challenge prominently shown
- Title and progress visible
- Today's tasks highlighted
- Quick actions available

## Test Data
| Field | Value |
|-------|-------|
| active_challenges | 1 |
| progress | 45% |

## Edge Cases
- Multiple active challenges (if allowed)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
