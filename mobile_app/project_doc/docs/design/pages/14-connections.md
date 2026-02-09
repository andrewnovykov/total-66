Page: Connections Manager

Basic Info
URL: /connections

Accessible by:
- Logged-in Users
- Coaches
- Admins

Purpose:
Central hub for managing all social relationships including followers, following, friends, and friend requests.

---

Layout

Header Section
- Logo (left) → links to Home
- Main navigation (same as global)
- User menu (right)

---

Main Content

+--------------------------------------------------+
|              [Stats Summary Bar]                 |
|   Following | Followers | Friends | Requests     |
+--------------------------------------------------+
|                                                  |
|        [Tab Navigation]                          |
|  Following | Followers | Friends | Requests      |
|                                                  |
+--------------------------------------------------+
|                                                  |
|        [Connections List]                        |
|        (Content varies by active tab)            |
|                                                  |
+--------------------------------------------------+

---

Stats Summary Bar
Purpose:
Quick overview of all connection counts at a glance.

Content
- Following count (clickable, activates Following tab)
- Followers count (clickable, activates Followers tab)
- Friends count (clickable, activates Friends tab)
- Requests count (clickable, activates Requests tab)

Visual Style
- Horizontal bar with equal-width sections
- Each section shows icon + count + label
- Active tab highlighted
- Badge on Requests if pending > 0

---

Tab: Following (People You Follow)

Purpose:
View and manage users you are following.

User Card Content
- Avatar (medium)
- Display name
- Username (@handle)
- Short bio (truncated)

Actions per Card
- "View Profile" button → navigates to /people/:username
- "Unfollow" button → removes follow relationship

Empty State
- "You're not following anyone yet"
- "Discover people to follow on the People page"
- CTA button: "Browse People" → /people

---

Tab: Followers (Your Followers)

Purpose:
View users who follow you.

User Card Content
- Avatar (medium)
- Display name
- Username (@handle)
- Short bio (truncated)

Actions per Card
- "View Profile" button → navigates to /people/:username
- "Remove" button → removes follower (blocks from following)

Empty State
- "No followers yet"
- "Share your goals to gain followers"

---

Tab: Friends

Purpose:
View accepted mutual friendships.

User Card Content
- Avatar (medium)
- Display name
- Username (@handle)
- Short bio (truncated)

Actions per Card
- "View Profile" button → navigates to /people/:username
- "Remove Friend" button → unfriends (with confirmation)

Empty State
- "No friends yet"
- "Send friend requests to build your network"
- CTA button: "Find Friends" → /people

---

Tab: Requests

Purpose:
Manage incoming and outgoing friend requests.

Sub-sections
1. Incoming Friend Requests
2. Sent Friend Requests

Incoming Request Card Content
- Avatar (medium)
- Display name
- Username (@handle)
- Short bio (truncated)
- Request received date

Actions per Incoming Request
- "Accept" button → accepts friendship
- "Decline" button → declines request

Sent Request Card Content
- Avatar (medium)
- Display name
- Username (@handle)
- Short bio (truncated)
- "Pending approval" status indicator

Actions per Sent Request
- "Cancel Request" button → withdraws the request

Empty States
- Incoming: "No pending friend requests"
  - Subtitle: "Friend requests will appear here"
- Sent: "No sent friend requests"

---

States

Loading
- Skeleton stats bar
- Tab navigation visible
- Skeleton user cards (3-5 placeholders)

Error State
- "Unable to load connections"
- Retry button

---

Mobile Behavior
- Stats bar becomes 2x2 grid
- Tab navigation horizontally scrollable
- User cards full-width, stacked vertically
- Action buttons become icon-only or slide-out actions

---

Interactions

Follow/Unfollow
- Instant optimistic UI update
- Toast confirmation: "You unfollowed [Name]"
- Undo option in toast (5 seconds)

Accept Friend Request
- Card animates to Friends tab
- Toast: "You are now friends with [Name]"

Decline Friend Request
- Card fades out
- Toast: "Friend request declined"

Cancel Sent Request
- Card fades out
- Toast: "Friend request cancelled"

Remove Friend
- Confirmation modal: "Remove [Name] as friend?"
- On confirm: Card fades out
- Toast: "You are no longer friends with [Name]"

Remove Follower
- Confirmation modal: "Remove [Name] from your followers?"
- On confirm: Card fades out
- Toast: "[Name] can no longer follow you"

---

Privacy Considerations
- Only shows connections to the logged-in user (private page)
- Cannot view other users' connection pages
- Relationship changes take effect immediately

---

Related Pages
- People Directory → /people
- User Profile → /people/:username
- My Goals → /my-goals
- Feed → /feed

---

Notes for Implementation
- All relationship operations must be server-validated
- Use Phoenix PubSub for real-time updates if another tab is open
- Paginate lists if > 50 connections
- Cache counts for performance
