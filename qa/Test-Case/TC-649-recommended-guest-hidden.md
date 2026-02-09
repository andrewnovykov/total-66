# TC-649: Recommended Hidden for Guests

## Linked User Story
- [US-609](../USER-STORY/US-609-recommended-people.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is not logged in (guest)

## Test Steps
1. Navigate to /people as guest
2. Look for "Recommended for You" section
3. Verify section not displayed

## Expected Results
- Recommended section hidden
- Other sections (top setters) visible
- No personalized recommendations for guests

## Test Data
| Field | Value |
|-------|-------|
| user_state | guest |
| recommended_visible | false |

## Edge Cases
- Guest with cookies from previous session

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
