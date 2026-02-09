# TC-654: Top Setters Profile Link

## Linked User Story
- [US-610](../USER-STORY/US-610-top-goal-setters.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- Top setters section visible

## Test Steps
1. View top goal setters section
2. Click "View Profile" on a user
3. Verify navigation to profile
4. Check profile loads correctly

## Expected Results
- Profile link works
- Navigates to /u/:username
- Profile page loads
- Can return to people page

## Test Data
| Field | Value |
|-------|-------|
| action | view_profile |
| target | /u/:username |

## Edge Cases
- Private profile viewed by guest

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
