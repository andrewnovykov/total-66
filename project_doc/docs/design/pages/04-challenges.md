Page: Challenges

Basic Info
URL: /challenges

Accessible by:
- Guests
- Logged-in Users
- Coaches
- Admins

Purpose:
Discover, join, and manage challenges. Challenges provide structured, repeatable programs—either admin-defined templates or user-created habit challenges.

---

Layout

Header Section
- Logo (left) → links to Home
- Main navigation:
  - Home
  - Goals
  - Challenges (active)
  - Groups
  - People
  - My Goals (logged-in only)
  - Coach Center (coach only)
  - Admin (admin only)
- User menu (right):
  - Profile / Logout (logged-in)
  - Login / Register (guest)

---

Main Content

+--------------------------------------------------+
|              [Page Intro / Tabs]                 |
+--------------------------------------------------+
|            [Search & Filter Bar]                 |
+--------------------------------------------------+
|                                                  |
|            [Challenges Grid/List]                |
|                                                  |
+--------------------------------------------------+
|               [Pagination / Load More]           |
+--------------------------------------------------+

Page Intro / Tabs
Purpose:
Help users understand challenge types and switch between views.

Tabs (or segmented control)
- Challenge Templates (default) — browse all templates (predefined + community)
- My Challenges (logged-in only) — user's personal challenges

Behavior:
- Default tab: Challenge Templates
- Tab selection persists in URL (query param)
- "My Challenges" tab only visible when logged in

---

Search & Filter Bar
Purpose:
Allow users to find relevant challenges quickly.

Search
- Text input: "Search challenges by name or keyword"

Filters
- Category (admin-defined categories)
- Challenge Type:
  - Predefined
  - Community
- Status (My Challenges tab only):
  - Active
  - Completed
  - Failed

Sorting
- Popular (default)
- Newest
- Most started (templates only — count of derived challenges)
- Ending soon (if duration exists)

---

Challenges Grid / List

### Template Cards (Challenge Templates tab)
Each template card displays:
- Challenge title
- Type badge: Predefined (Admin) / Community (User)
- Short description
- Category badge
- "X people started" count (number of derived personal challenges)
- Optional duration label (e.g. "30 days")
- Actions: "View Template" / "Start Challenge" (logged-in only)
- "Already Started" indicator if user has an active personal challenge from this template

### Personal Challenge Cards (My Challenges tab)
Each personal challenge card displays:
- Challenge title
- Type badge: Predefined / Community
- Status badge: Active / Completed / Failed
- Progress: "Day X of Y"
- Start date — End date
- Actions: "Continue" (active) / "View" (completed/failed)
- NO participant count (solo experience)

---

Challenge Types — Behavior Differences

Predefined Challenges (Admin-created)
- Structure: Phases → Steps (defined by admin)
- User Capabilities: Start from template, view, complete steps, post updates (if enabled)
- Restrictions: Cannot edit phases or steps

Community Challenges (User-created)
- Structure: Tasks with schedules
- Schedule options: Every day, Twice a week, Every other day, Mon–Fri, Custom weekdays
- Creator can edit tasks/schedules; participants cannot

---

Start Challenge Flow
- User clicks "Start Challenge" on a template
- System creates a personal challenge copy (is_template=false, template_id set)
- System copies phases/steps/tasks to the personal challenge
- System auto-joins user as participant
- System calculates start_date (today) and end_date (today + duration_days)
- Redirects to the personal challenge page
- If user already started this template: show "Already Started" banner with link to existing personal challenge

---

Visibility Rules
- Public challenges: visible to everyone
- Friends-only challenges: visible only to accepted friends
- Private challenges: visible only to creator
- Visibility applies to detail page, tasks/steps, feed, comments

---

Challenge Show Page — Template

URL: /challenges/:id (where challenge.is_template = true)

Purpose:
Preview a challenge template and start it.

Layout:
+--------------------------------------------------+
|  [Title] [Type Badge] [Duration Badge]           |
|  [Description]                                    |
+--------------------------------------------------+
|  [Structure Preview]                              |
|  - Phase 1: Step titles...                        |
|  - Phase 2: Step titles...                        |
|  OR                                               |
|  - Task list with schedule labels                 |
+--------------------------------------------------+
|  [Start Challenge Button]                         |
|  OR [Already Started Banner → link]               |
+--------------------------------------------------+
|  [People Who Started]                             |
|  - Avatar row (first 5-10 users)                  |
|  - "X people started this challenge"              |
+--------------------------------------------------+

Content:
- Header: title, type badge (Predefined/Community), duration badge
- Description: full challenge description
- Structure Preview: read-only list of phases/steps or tasks with schedules
- "Start Challenge" button (logged-in only)
- If user already started: "Already Started" banner with link to their personal challenge
- "People Who Started" section: avatars + count of users who derived a personal challenge
- NO progress tracking, NO daily tasks, NO feed

---

Challenge Show Page — Personal Challenge

URL: /challenges/:id (where challenge.is_template = false)

Purpose:
Track progress, complete daily tasks, and view challenge feed.

Layout:
+--------------------------------------------------+
|  [Title] [Status Badge] [Type Badge]             |
|  "Day X of Y" [Progress Bar]                     |
+--------------------------------------------------+
|  [Actions]                                        |
|  - Fail Challenge (red)                           |
|  - Delete (owner only, if applicable)             |
+--------------------------------------------------+
|  [Today's Tasks]                                  |
|  ☐ Task 1 — [Done] [Failed]                      |
|  ☐ Task 2 — [Done] [Failed]                      |
|  ☐ Task 3 — [Done] [Failed]                      |
|  [Optional Note textarea]                         |
|  [Finish Day X Button]                            |
+--------------------------------------------------+
|  [Challenge Feed]                                 |
|  - Day 5: "3/4 tasks completed" + note            |
|    - 2 comments, 5 likes                          |
|  - Day 4: "4/4 tasks completed"                   |
|    - 1 comment, 3 likes                           |
|  - Day 3: ...                                     |
+--------------------------------------------------+

### Header
- Title of the challenge
- Status badge: Active (green) / Completed (blue) / Failed (red)
- Type badge: Predefined / Community
- "Day X of Y" label where X = Date.diff(today, start_date) + 1, Y = duration_days
- Progress bar: X/Y days completed (based on check-ins submitted)

### Actions
- "Fail Challenge" button (red) — replaces "Leave" for personal challenges
  - Opens confirmation modal with optional failure_reason field
- "Delete" button (only if user is owner and challenge allows deletion)
- NO "Leave" button — personal challenges are solo
- NO Participants section — personal challenges are solo

### Today's Tasks
- List of tasks scheduled for today based on schedule_type/schedule_weekdays
- Each task has toggle buttons: [Done] / [Failed]
- Optional note textarea for daily reflection
- "Finish Day X" button — submits the daily check-in
- Disabled if check-in already submitted for today

### Challenge Feed
- List of DailyCheckIn entries, newest first
- Each entry shows:
  - "Day X" label
  - Task summary: "3/4 tasks completed" (completed_tasks / total_tasks)
  - Optional note text
  - Comment count + reaction (like) count
  - Expandable comments section
- Users can add comments and react (like) to any check-in
- Feed visibility follows challenge visibility

---

States

Loading
- Skeleton challenge cards
- Tabs visible but disabled

Empty States
- "No challenges match your filters." → CTA: Clear filters
- "No community challenges yet." → CTA: Create Challenge (logged-in only)
- "You haven't started any challenges yet." → CTA: Browse Templates (My Challenges tab)

Challenge Failed State
- Grayed-out progress bar
- "Failed" badge (red) on status
- Failure reason displayed (if provided)
- Today's Tasks section hidden
- Feed remains visible (read-only)
- "Start Again" link to the parent template (if template still exists)

Check-in Already Done State
- Today's tasks shown as read-only with done/failed indicators
- "Day X Completed" label replaces "Finish Day X" button
- Note displayed (if provided)

No Tasks Today State
- "No tasks scheduled for today" message
- Shows next scheduled task day
- Feed still visible below

Error State
- "Unable to load challenges." → Retry

---

Pagination / Load More
- Paginated or infinite scroll
- URL reflects current page

---

Mobile Behavior
- Tabs horizontally scrollable
- Filters in slide-up drawer
- Cards in single-column list
- Sticky bottom CTA: "Create Challenge" (logged-in only)
- Today's Tasks section uses full-width toggles for mobile

---

Notes for Implementation
- Templates and personal challenges share some UI but differ in permissions and content
- Starting a challenge creates a personal copy — original template is not modified
- Visibility checks enforced server-side
- Daily check-in uses polymorphic Comment and Reaction tables with target_type='daily_check_in'
- Feed pagination separate from challenge list pagination

---

Related Pages
- Challenge Detail → /challenges/:challengeId
- My Goals → /my-goals
- Create Challenge → /create
