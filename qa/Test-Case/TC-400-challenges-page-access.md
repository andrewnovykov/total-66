# TC-400: Access Challenges Page

## Linked User Story
- [US-400](../USER-STORY/US-400-browse-challenges.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in

## Test Steps
1. Click "Challenges" in navigation
2. Observe challenges page loads

## Expected Results
- Challenges page is displayed
- Predefined challenges are listed
- Page loads without errors

## Test Data
| Field | Value |
|-------|-------|
| nav_item | Challenges |

## Edge Cases
- Guest user access (should show but no join)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/challenge_live_test.exs`
