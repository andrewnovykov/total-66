# TC-648: Recommended Based on Category

## Linked User Story
- [US-609](../USER-STORY/US-609-recommended-people.md)

## Test Type
Unit / Integration

## Priority
Low

## Preconditions
- User has goals in specific categories
- Other users have goals in same categories

## Test Steps
1. Create user with fitness goals
2. Check recommendations
3. Verify users with fitness goals appear
4. Change user's categories
5. Verify recommendations update

## Expected Results
- Users with shared categories recommended
- Category overlap weighted in algorithm
- Recommendations update with profile changes

## Test Data
| Field | Value |
|-------|-------|
| user_category | fitness |
| expected_recommendations | fitness_users |

## Edge Cases
- No category overlap with anyone

## Automation Status
- [ ] Automated in: `test/heads_up/recommendations_test.exs`
