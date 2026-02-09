# TC-650: Follow from Recommended Section

## Linked User Story
- [US-609](../USER-STORY/US-609-recommended-people.md)

## Test Type
E2E / LiveView

## Priority
Low

## Preconditions
- User is logged in
- Recommended people displayed

## Test Steps
1. View recommended people section
2. Click "Follow" on a recommended user
3. Verify follow action succeeds
4. Check if user removed from recommendations

## Expected Results
- Can follow directly from recommendation
- Follow button changes to "Following"
- May be removed from recommendations after following
- Follower count updates

## Test Data
| Field | Value |
|-------|-------|
| action | follow |
| context | recommended_section |

## Edge Cases
- Recommendation refreshes after follow

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/people_live_test.exs`
