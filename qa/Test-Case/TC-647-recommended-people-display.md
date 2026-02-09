# TC-647: Recommended People Display

## Linked User Story
- [US-609](../USER-STORY/US-609-recommended-people.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- User is logged in
- User has activity that enables recommendations

## Test Steps
1. Navigate to /people
2. Observe "Recommended for You" section
3. Verify user cards displayed
4. Check recommendation relevance

## Expected Results
- Recommended section visible
- Shows relevant user suggestions
- User cards with actions
- Based on user's interests

## Test Data
| Field | Value |
|-------|-------|
| section | recommended_for_you |
| max_shown | 5 |

## Edge Cases
- New user with no data for recommendations

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
