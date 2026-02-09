# Feature 3: Categories (Admin-managed)

## User Story
“As an admin, I want to create and delete goal categories so that goals are organized and discoverable.”

## Inputs
- Category name (required)
- Optional: image/icon
- Optional: description

## Outputs
- Categories available in Goal creation & filtering

## Rules
- Users cannot create categories
- Deleting a category must not break existing goals:
  - Either reassign to “Uncategorized” or block deletion until reassigned
