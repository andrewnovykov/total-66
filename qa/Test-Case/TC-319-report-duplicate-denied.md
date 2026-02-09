# TC-319: Cannot Report Same Item Twice

## Linked User Story
- [US-304](../USER-STORY/US-304-spam-reporting.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- User has already reported the item

## Test Steps
1. Navigate to previously reported item
2. Attempt to report again

## Expected Results
- Report button disabled/hidden
- Message: "Already reported"
- No duplicate report created

## Test Data
| Field | Value |
|-------|-------|
| previous_report | true |

## Edge Cases
- Different report reasons

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/report_live_test.exs`
