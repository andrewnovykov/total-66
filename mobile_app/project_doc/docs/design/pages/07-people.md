Page: People

Basic Info
URL: /people

Accessible by:
- Guests
- Logged-in Users
- Coaches
- Admins

Purpose:
Discover people on the platform, follow goal creators, build friendships, and find disciplined users worth tracking.

---

Layout

Header Section
- Logo (left) → links to Home
- Main navigation:
  - Home
  - Goals
  - Challenges
  - Groups
  - People (active)
  - My Goals (logged-in only)
  - Coach Center (coach only)
  - Admin (admin only)
- User menu (right):
  - Profile / Logout (logged-in)
  - Login / Register (guest)

---

Main Content

+--------------------------------------------------+
|            [Search & Filter Bar]                 |
+--------------------------------------------------+
|                                                  |
|        [Recommended / Following Section]         |
|                                                  |
+--------------------------------------------------+
|                                                  |
|          [Top Goal Setters Section]              |
|                                                  |
+--------------------------------------------------+
|                                                  |
|               [People Grid/List]                 |
|                                                  |
+--------------------------------------------------+
|               [Pagination / Load More]           |
+--------------------------------------------------+

Search & Filter Bar
Purpose:
Allow users to find people quickly and narrow results.

Search
- Text input: “Search people by name or nickname”

Filters
- Activity level: Highly active / Active this week / Recently joined
- Role: All / Coach
- Friendship status (logged-in only): Not friends / Friends / Pending requests

Sorting
- Recommended (default for logged-in users)
- Most active
- Most followed
- Newest

---

Recommended / Following Section
Purpose:
Surface relevant people first for logged-in users.

Logged-in Users See
- Recommended for You (based on categories, followed goals, shared challenges, activity)
- Following (people the user already follows)

Guests
- Section hidden

---

Top Goal Setters Section
Purpose:
Highlight disciplined users with strong consistency.

User Card Content
- Avatar
- Display name / nickname
- Level
- Goals count
- Active streak indicator
- Actions: View Profile / Follow (logged-in only)

---

People Grid / List

User Card Content
- Avatar
- Display name / nickname
- Short bio (optional)
- Level badge
- Stats: Followers count, Active goals count
- Actions: Follow / Unfollow, Add Friend / Pending / Friends, View Profile

---

Social Actions

Follow / Unfollow
- One-way relationship
- Immediately updates follower count

Friend Requests
- Button states: Add Friend / Request Sent / Accept / Decline / Friends
- Friends unlock friends-only goals/challenges

---

Visibility Rules
- Guests can view public profiles only
- Logged-in users can follow and send friend requests
- Private data must not leak via People list

---

States

Loading
- Skeleton user cards
- Search bar visible but disabled

Empty States
- “No people found.” → CTA: Clear filters
- “Follow goals and people to get recommendations.”

Error State
- “Unable to load people.” → Retry

---

Mobile Behavior
- Search bar collapses into icon
- Filters open in slide-up panel
- Cards displayed in single-column list
- Follow / Friend actions moved into primary buttons

---

Notes for Implementation
- Do not expose private/friends-only content through previews
- All social actions must validate auth + permissions server-side
- Recommendation logic can be simple for MVP (category overlap + activity)

---

Related Pages
- User Profile → /u/:username
- Goals → /goals
- Challenges → /challenges
