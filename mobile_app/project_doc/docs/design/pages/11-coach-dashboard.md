Page: Coach Group Goal Dashboard

Basic Info
URL: /coach/group-goals/:groupGoalId

Accessible by:
- Coach who owns this group goal only

Purpose:
Provide coaches with detailed, real-time visibility into participant progress for a specific group goal program.

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
  - Coach Center
- User menu (right): Profile / Logout

---

Main Content

+--------------------------------------------------+
|        [Group Goal Header & Summary]             |
+--------------------------------------------------+
|                                                  |
|      [Overall Progress & Health Metrics]         |
|                                                  |
+--------------------------------------------------+
|                                                  |
|      [Participants Progress Table]               |
|                                                  |
+--------------------------------------------------+
|                                                  |
|      [Activity & Alerts Section]                 |
|                                                  |
+--------------------------------------------------+

Group Goal Header & Summary
Purpose:
Clearly identify the group goal and its current state.

Content
- Group goal title
- Category badge
- Status badge: Active / Archived
- Start date
- Total participants count
- Short description (read-only)

Actions
- Add Participants (if Active)
- Archive Group Goal
- Back to Coach Center

---

Overall Progress & Health Metrics
Purpose:
Give the coach a quick health snapshot of the group.

Metrics Cards
- Active Participants: number / total
- Average Completion: average % progress
- At-Risk Participants: count
- Completion Rate: % completed

---

Participants Progress Table
Purpose:
Track each participant individually.

Table Columns
- Avatar
- Name
- Status (Active / Frozen / Completed / Failed)
- Progress bar (% of steps completed)
- Current Phase
- Last Activity (date/time)
- Consistency label (Strong / Weak / Inactive)
- Action: View Participant Goal

---

Activity & Alerts Section
Purpose:
Surface behavior patterns and problems early.

Recent Activity Feed
- Step completions
- Goal status changes
- Posts/updates from participants

Alerts / Flags
- “User X has no activity in 5 days”
- “User Y froze their goal”
- “Multiple missed steps detected”

---

States

Loading
- Skeleton metrics cards
- Skeleton participant table
- Placeholder activity feed

Empty States
- “No participants enrolled.” → CTA: Add Participants
- “No progress updates yet.”

Error State
- “Unable to load group goal dashboard.” → Retry
- “You don’t have access to this group goal.”

---

Mobile Behavior
- Metrics cards stack vertically
- Participant table becomes card-based list
- Alerts collapse into expandable section
- Sticky “Add Participants” button (if allowed)

---

Permissions & Rules
- Coaches can view all participant progress
- Coaches cannot edit participant goals or status
- All data shown scoped to this group goal only

---

Notes for Implementation
- Read-only with respect to participant progress
- Metrics computed dynamically
- Optimize heavy queries

---

Related Pages
- Coach Center → /coach
- Participant Goal Detail → /goals/:goalId
- My Goals (participant view) → /my-goals
