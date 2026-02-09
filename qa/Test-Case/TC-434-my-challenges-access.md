# TC-434: Access My Challenges Section

## Linked User Story
- [US-409](../USER-STORY/US-409-my-challenges-dashboard.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in

## Test Steps
1. Navigate to dashboard
2. Find "My Challenges" section
3. Click to access

## Expected Results
- My Challenges section accessible
- Active challenges shown
- History available
- Quick actions visible

## Test Data
| Field | Value |
|-------|-------|
| section | My Challenges |

## Edge Cases
- No active challenges

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
