Page: Create

Basic Info
URL: /create

Accessible by:
- Logged-in Users
- Coaches
- Admins

Purpose:
Central creation entry point for Goals and Challenges (and group templates for coaches).

---

Layout

Header Section
- Logo (left) → links to Home
- Main navigation (same as other pages)
- User menu (right)

---

Main Content

+--------------------------------------------------+
|              [Create Type Selector]              |
+--------------------------------------------------+
|                                                  |
|              [Creation Form Area]                |
|                                                  |
+--------------------------------------------------+

Create Type Selector
- Goal
- Challenge
- Group Goal Template (coach only)

---

Creation Form Area

Goal Form (summary)
- Title, description, category, visibility, due date
- Phases and steps builder
- Save → creates Active goal if under 3-item limit

Challenge Form (summary)
- Choose: Predefined (join) or Custom (create)
- Custom challenge tasks + schedules
- Save → creates Active challenge if under 3-item limit

Group Goal Template (coach only)
- Title, category
- Phases/steps builder
- Save draft → proceed to participant selection in Coach Center

---

Rules
- 3 active items limit enforced on save for goals/challenges
- Visibility rules: public / friends / private
- Predefined challenges are not editable from here (join flow only)

---

States

Loading
- Disable form
- Show spinner on Save

Error
- Inline validation errors
- “Unable to create item.” → Retry

---

Mobile Behavior
- Type selector becomes stacked cards
- Forms in single column
- Primary action button full width

---

Related Pages
- My Goals → /my-goals
- Coach Center → /coach
