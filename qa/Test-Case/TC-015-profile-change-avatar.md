# TC-015: Change Profile Avatar

## Linked User Story
- [US-004](../USER-STORY/US-004-profile-management.md)

## Test Type
E2E / LiveView

## Priority
Medium

## Preconditions
- User is logged in
- Valid image file available

## Test Steps
1. Navigate to profile edit page
2. Click change avatar button
3. Upload new image file
4. Save changes

## Expected Results
- Avatar is updated
- Preview shows new image
- New avatar displayed on profile

## Test Data
| Field | Value |
|-------|-------|
| image_file | valid_avatar.jpg |
| image_size | < 5MB |

## Edge Cases
- Invalid file type
- File too large
- No file selected

## Automation Status
- [ ] Automated in: `test/heads_up_web/live/profile_live_test.exs`
