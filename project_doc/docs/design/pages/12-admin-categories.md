Page: Admin – Goal Categories

Basic Info
URL: /admin/categories

Accessible by:
- Admins only

Purpose:
Allow admins to create, edit, and delete goal/challenge categories used across the platform.

---

Layout

Header Section
- Logo (left) → links to Home
- Main navigation:
  - Home
  - Goals
  - Challenges
  - Groups
  - People
  - Admin (active)
- User menu (right): Profile / Logout

---

Main Content

+--------------------------------------------------+
|            [Admin Page Header]                   |
+--------------------------------------------------+
|              [Action Bar]                        |
+--------------------------------------------------+
|                                                  |
|              [Categories Table]                  |
|                                                  |
+--------------------------------------------------+

Admin Page Header
- Page title: “Goal Categories”
- Helper text: “Categories define how goals and challenges are organized across the platform.”

Action Bar
- Button: Create Category

Categories Table
Each row represents one category:
- Category name
- Description (optional)
- Usage count (goals + challenges)
- Status: Active / Disabled
- Actions: Edit / Delete (if allowed)

Category Create / Edit Flow
Fields:
- Name (required, unique)
- Description (optional)
- Status: Active / Disabled

Delete Rules
- If category has no associated goals/challenges: delete allowed
- If category is in use: delete blocked with guidance

---

States

Loading
- Skeleton table rows

Empty
- “No categories created yet.” → CTA: Create First Category

Error
- “Unable to load categories.” → Retry

---

Permissions & Rules
- Admins only
- Category changes affect goal/challenge creation and filters

---

Mobile Behavior
- Table converts to stacked cards
- Actions in overflow menu

---

Related Pages
- Admin Challenges → /admin/challenges
- Goals → /goals
- Challenges → /challenges
