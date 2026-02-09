Page: Coach Center

Basic Info
URL: /coach

Accessible by:
- Coaches only

Purpose:
Create and manage group goal templates, enroll participants, and start group goals.

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
  - My Goals
  - Coach Center (active)
- User menu (right): Profile / Logout

---

Main Content

+--------------------------------------------------+
|              [Coach Summary]                     |
+--------------------------------------------------+
|                 [Action Bar]                     |
+--------------------------------------------------+
|                                                  |
|            [Group Goal Templates List]           |
|                                                  |
+--------------------------------------------------+
|                                                  |
|            [Active Group Goals List]             |
|                                                  |
+--------------------------------------------------+

Coach Summary
- Total templates
- Active group goals
- At-risk participants (count)

Action Bar
- Create Group Goal Template

Group Goal Templates List
Each template card:
- Template title
- Category
- Phases/steps count
- Status (Draft / Ready)
- Actions: Edit / Add Participants / Start

Active Group Goals List
Each group goal card:
- Group goal name
- Start date
- Participants count
- Status (Active / Archived)
- Actions: View Dashboard / Archive

---

Flows
- Create Template → add phases/steps → save
- Add Participants → search users → invite/add
- Start Group Goal → creates participant goal instances (Active if under 3-item limit)

---

States

Loading
- Skeleton lists

Empty
- “No group goal templates yet.” → CTA: Create Template
- “No active group goals.”

Error
- “Unable to load coach center.” → Retry

---

Mobile Behavior
- Lists stack vertically
- Primary CTA sticky at bottom

---

Related Pages
- Coach Group Goal Dashboard → /coach/group-goals/:groupGoalId
- Create → /create (optional entry)
