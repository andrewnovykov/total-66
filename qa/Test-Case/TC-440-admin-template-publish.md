# TC-440: Admin Publish Template

## Linked User Story
- [US-410](../USER-STORY/US-410-admin-create-challenge-template.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- Admin user is logged in
- Template is created but unpublished

## Test Steps
1. Navigate to template
2. Click "Publish" button
3. Confirm publication
4. Check user-facing page

## Expected Results
- Template is published
- Template visible to users
- Users can join
- Status shows "published"

## Test Data
| Field | Value |
|-------|-------|
| initial_status | draft |
| final_status | published |

## Edge Cases
- Unpublish published template

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/admin/challenge_live_test.exs`
