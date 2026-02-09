# TC-318: Report Post as Spam

## Linked User Story
- [US-304](../USER-STORY/US-304-spam-reporting.md)

## Test Type
E2E / LiveView

## Priority
High

## Preconditions
- User is logged in
- Post is visible

## Test Steps
1. Navigate to post
2. Click red flag icon
3. Select report reason
4. Submit report

## Expected Results
- Report is created
- Confirmation message shown
- Cannot report same post again

## Test Data
| Field | Value |
|-------|-------|
| reason | inappropriate |

## Edge Cases
- Report own post (should fail)

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/report_live_test.exs`
