# TC-320: Auto-Hide After 3 Reports

## Linked User Story
- [US-304](../USER-STORY/US-304-spam-reporting.md)

## Test Type
Integration

## Priority
Critical

## Preconditions
- Item has 2 existing reports

## Test Steps
1. Third user reports the item
2. System processes report
3. Check item visibility

## Expected Results
- Item is auto-hidden
- Sent to moderation queue
- Not visible to public
- Owner is notified

## Test Data
| Field | Value |
|-------|-------|
| report_count | 3 |
| threshold | 3 |

## Edge Cases
- Reports from same IP
- Rapid reporting

## Automation Status
- [ ] Automated in: `test/heads_up/moderation_test.exs`
