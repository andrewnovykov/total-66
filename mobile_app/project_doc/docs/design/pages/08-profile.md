Page: User Profile

Basic Info
URL: /u/:username

Accessible by:
- Guests
- Logged-in Users
- Coaches
- Admins

Purpose:
Show a user’s identity, consistency, and public progress. This page is the primary representation of a person on the platform.

---

Layout

Header Section
- Logo (left) → links to Home
- Main navigation (same as global)
- User menu (right)

---

Main Content

+--------------------------------------------------+
|              [Profile Header]                    |
+--------------------------------------------------+
|                                                  |
|        [Stats & Social Actions Section]          |
|                                                  |
+--------------------------------------------------+
|                                                  |
|        [Commitment Chart / Activity]             |
|                                                  |
+--------------------------------------------------+
|                                                  |
|        [User Goals & Challenges List]            |
|                                                  |
+--------------------------------------------------+

Profile Header
Purpose:
Clearly identify the user and their role on the platform.

Content
- Avatar (large)
- Display name
- Nickname / username
- Short bio (optional)
- Role badge (Coach, if applicable)
- Level badge

---

Stats & Social Actions Section

Stats
- Followers count
- Following count
- Friends count
- Total goals created
- Active goals count

Social Actions (Contextual)
- Guests: “Sign in to follow”
- Logged-in Users (not owner): Follow / Unfollow, Add Friend / Pending / Accept / Friends
- Profile Owner: Edit Profile, View My Goals

---

Commitment Chart / Activity
Purpose:
Visualize consistency and accountability over time.

Chart Behavior
- GitHub-style heatmap
- Each day represents: step completions, task completions, goal updates
- Color intensity based on activity count
- Hover/tap day shows activity summary
- Date range: last 30 days (default), 90 days / 1 year optional

---

User Goals & Challenges List
Purpose:
Show what the user is working on or has completed.

Tabs (optional)
- Active
- Completed
- Failed

Item Card Content (visibility rules apply):
- Title
- Type badge: Goal / Challenge / Group Goal
- Status badge
- Category badge
- Progress indicator
- Visibility badge (owner only)

Actions
- View item
- Follow Goal (goals, logged-in only)

---

Visibility Rules

Public Profile
- Guests can view profile header, public goals/challenges, aggregated commitment chart

Friends-only Content
- Only accepted friends can view friends-only goals/challenges and related activity details

Private Content
- Visible only to profile owner
- Never shown on public profile or to friends

---

States

Loading
- Skeleton header
- Skeleton stats
- Placeholder commitment chart
- Skeleton item cards

Empty States
- “This user hasn’t started any goals yet.”
- “No public activity to show.”

Error State
- “Unable to load profile.” → Retry
- “User not found.”

---

Mobile Behavior
- Profile header stacks vertically
- Social actions become primary buttons
- Commitment chart scrollable horizontally
- Items list becomes single-column

---

Notes for Implementation
- Username in URL must be unique
- All visibility checks enforced server-side
- Commitment chart must not leak private/friends-only details

---

Related Pages
- People → /people
- Goals → /goals
- My Goals → /my-goals
- Coach Center → /coach (if user is coach)
