Page: Admin – Predefined Challenges

Basic Info
URL: /admin/challenges

Accessible by:
- Admins only

Purpose:
Allow admins to create, edit, and manage predefined challenge templates that users can join.

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
|          [Predefined Challenges Table]           |
|                                                  |
+--------------------------------------------------+

Admin Page Header
- Page title: “Predefined Challenges”
- Helper text: “Predefined challenges are structured programs with fixed phases and steps that users can join.”

Action Bar
- Button: Create Predefined Challenge

Predefined Challenges Table
Each row represents one challenge template:
- Challenge title
- Category
- Description (truncated)
- Participants count
- Status: Active / Disabled
- Actions: Edit Template / Disable / Enable / Delete (if allowed)

Create / Edit Flow
Fields:
- Challenge title (required)
- Description (optional)
- Category (admin-defined)
- Status: Active / Disabled

Structure Builder
- Add/edit/reorder phases
- Add/edit/reorder steps
- At least 1 phase required; each phase must have at least 1 step

Disable / Enable Rules
- Disable: new users cannot join; existing participants unaffected
- Enable: challenge becomes joinable again

Delete Rules
- If no participants: delete allowed
- If participants exist: delete blocked; must disable instead

---

States

Loading
- Skeleton table rows

Empty
- “No predefined challenges created yet.” → CTA: Create First Challenge

Error
- “Unable to load challenges.” → Retry

---

Permissions & Rules
- Admins only
- Structure immutable for users
- Status changes should be logged

---

Mobile Behavior
- Table converts to stacked cards
- Actions grouped under overflow menu

---

Related Pages
- Challenges → /challenges
- Admin Categories → /admin/categories
