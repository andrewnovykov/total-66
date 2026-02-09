# TC-663: Feed Visibility Enforcement

## Linked User Story
- [US-612](../USER-STORY/US-612-social-feed.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User follows users with various content visibility

## Test Steps
1. Follow user with private goals
2. Follow user with friends-only goals (not friend)
3. Follow user with public goals
4. View feed
5. Verify only public content shown

## Expected Results
- Only public content in feed
- Private content never shown
- Friends-only only if friends
- Visibility rules enforced

## Test Data
| Field | Value |
|-------|-------|
| visibility_types | public, private, friends_only |
| expected_shown | public_only |

## Edge Cases
- Followed user changes visibility

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/feed_live_test.exs`
