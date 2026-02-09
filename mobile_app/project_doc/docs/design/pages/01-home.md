Page: Home

Implementation Status: REDESIGNED (2026-02-06)
Design System: "Soft Modern" (ux-ui.md)

---

Basic Info
- URL: /
- Controller: PageController.home/2
- Template: page_html/home.html.heex
- Accessible by:
  - Guests
  - Logged-in Users
  - Coaches
  - Admins
- Purpose:
  Primary discovery and entry point. Show what's happening on the platform right now and guide users to goals, challenges, groups, and people.

---

Implementation Notes

Layout Type: App Shell pattern — permanent left sidebar + center feed + right sidebar (desktop); single column with mobile header + drawer + bottom nav (mobile)
Background: Cool blue (#F0F4FF) set on body and main content area
Font: Plus Jakarta Sans (loaded in root.html.heex, with Be Vietnam Pro and Noto Sans fallbacks)

Reusable Components Used:
- HeadsUpWeb.Components.UI.Card - Base card wrapper (rounded-[40px], soft-shadow, hover variant)
- HeadsUpWeb.Components.UI.Avatar - User avatars with gradient initials fallback
- HeadsUpWeb.Components.UI.ProgressBar - Goal progress visualization (indigo color)
- HeadsUpWeb.Components.UI.SectionHeader - Section titles with "View All" links
- HeadsUpWeb.Components.UI.EmptyState - Empty content placeholders with action slot
- HeadsUpWeb.Components.UI.BottomNav - Mobile fixed bottom navigation (5 items)

App Layout Helpers (layouts.ex):
- sidebar_link/1 - Left sidebar navigation links (px-6 py-4 rounded-2xl)
- drawer_link/1 - Slide-out drawer menu links (px-6 py-3 rounded-2xl, with x_click attr)

Custom CSS (root.html.heex <style>):
- .custom-scrollbar - Thin 5px scrollbar with transparent track
- .soft-shadow - Subtle box-shadow: 0 10px 40px -10px rgba(0,0,0,0.05)

---

Layout

App Shell Architecture (implemented in app.html.heex)

Root container:
- bg-[#F0F4FF], min-h-screen, flex center
- Alpine.js x-data for drawer state: { menuOpen, closeMenu() }
- Escape key and outside-click close drawer

App shell:
- bg-white, max-w-[1920px], rounded-[48px], shadow-2xl, border border-slate-100/60
- Full viewport height on desktop: h-[calc(100vh-24px)]
- lg:p-3 outer padding (gives the blue background peek effect)

Desktop Layout (lg: and above):

+------------------+------------------------------+-------------------+
| Left Sidebar     | Center Content               | Right Sidebar     |
| w-[340px]        | flex-grow                    | w-[420px]         |
| (hidden < lg)    | p-5 / sm:p-8 / lg:p-10      | (hidden < xl)     |
+------------------+------------------------------+-------------------+
| Logo             | Hero Banner                  | Popular Groups    |
| Profile Card     | Goal Categories              | Suggestions       |
|  (or Welcome)    | Challenge Categories         | Quick Stats       |
| Nav: Browse      | Top Goal-Setters             |                   |
| Nav: My Stuff    | Active Goals Feed            |                   |
| Nav: Coach       |                              |                   |
| Nav: Admin       |                              |                   |
| Nav: Account     |                              |                   |
| Promo Card       |                              |                   |
+------------------+------------------------------+-------------------+

Mobile Layout (< lg):

+----------------------------------------+
| Mobile Header (sticky, backdrop-blur)  |
|  Logo | [Create] [Login/Signup] [Menu] |
+----------------------------------------+
| Center Content (full width, pb-20)     |
|  Hero → Categories → Goal-Setters →   |
|  Active Goals Feed                     |
+----------------------------------------+
| Bottom Nav (fixed, 5 items)            |
+----------------------------------------+

---

Left Sidebar (Desktop Only)

Visibility: hidden lg:flex
Width: w-[340px] flex-shrink-0
Style: bg-white/60 backdrop-blur-md, border-r border-slate-100, p-8, overflow-y-auto custom-scrollbar

Logo:
- 44px blue gradient icon (from-blue-500 to-indigo-600 rounded-xl) with checkmark SVG
- "HeadsUp" text-2xl font-extrabold tracking-tight
- Links to /

Profile Card (logged-in):
- bg-slate-50/80 rounded-3xl border border-slate-100 p-6
- 80px avatar with gradient ring (from-blue-500 to-indigo-600), green online dot (bottom-right)
- User name (font-bold text-lg) + @username (text-slate-400 text-xs)

Welcome Card (guest):
- Same card style
- 64px gradient placeholder icon (hero-user)
- "Welcome!" heading + "Join HeadsUp today"
- "Get Started" CTA → /users/register (blue gradient button, shadow-lg shadow-blue-500/20)

Navigation Sections:
1. Browse: Home, Goals, Challenges, Groups, People
2. My Stuff (logged-in only): My Goals, My Challenges, Connections, Feed, Create Goal, Create Challenge
3. Coach (coach/admin only): Coach Center
4. Admin (admin only): Goal Categories, Challenge Categories
5. Account (border-t separator): View Profile, Settings, Log out (logged-in) OR Log in, Register (guest)
   - Log out link has red hover: hover:bg-red-50 hover:text-red-600

Bottom Promo Card (logged-in only):
- bg-gradient-to-br from-blue-600 to-indigo-700 rounded-3xl p-6
- shadow-lg shadow-blue-500/20
- "Create a Goal" title + "Track progress & build momentum" subtitle
- "New Goal" white CTA button → /goals/new
- Decorative hero-rocket-launch icon (opacity-20, bottom-right)

---

Mobile Header

Visibility: lg:hidden, sticky top-0 z-40
Style: bg-white/95 backdrop-blur-lg border-b border-slate-100

Content:
- Left: Logo (36px icon + "HeadsUp" text-lg)
- Right actions:
  - Logged-in: "Create" button (blue gradient pill) → /goals/new, "Create" label hidden on xs (hidden sm:inline)
  - Guest: "Log in" text link + "Sign up" blue gradient pill
  - Hamburger button (40px, rounded-xl bg-slate-50) → toggles drawer
  - Hamburger icon swaps to X when open (Alpine x-show)

---

Slide-out Drawer (Mobile)

Trigger: Hamburger button in mobile header
Position: fixed right-0, z-50, w-[320px] max-w-[88vw]
Style: bg-white shadow-2xl rounded-l-3xl
Animation: Alpine x-transition, translate-x slide (220ms enter, 160ms leave)
Close: Escape key, outside click, close button, link x_click

Header: "Menu" label + close button (8x8 rounded-lg)

Sections (identical structure to sidebar):
1. Browse: Home, Goals, Challenges, Groups, People
2. My Stuff (logged-in): My Goals, My Challenges, Connections, Feed, Create Goal, Create Challenge
3. Coach (coach/admin): Coach Center
4. Admin (admin): Goal Categories, Challenge Categories
5. Account: View Profile, Settings, Log out / Log in, Register

Promo Card (logged-in only):
- Same as sidebar promo but slightly smaller (p-5, rounded-2xl)
- "Create a Goal" + "New Goal" CTA

---

Hero / Intro Section [IMPLEMENTED]

Implementation: Blue gradient banner (from-blue-600 to-indigo-600), rounded-[40px], soft-shadow
Padding: p-8 / sm:p-10 / lg:p-12
Layout: flex items-center justify-between, text-white

Left content (max-w-xl):
- Badge: "New Challenge" — bg-blue-500/50 text-blue-100, text-xs font-bold, uppercase tracking-wider, rounded-full px-4 py-1.5
- Headline: "Set fewer goals. Finish more." — text-3xl / sm:text-4xl / lg:text-5xl font-extrabold
- Subtext: "A goal-first social network with structure, accountability, and real progress." — text-blue-100, text-lg / lg:text-xl
- Primary CTA:
  - Logged-in: "Create Your Goal" → /goals/new
  - Guest: "Get Started" → /users/register
  - Style: bg-white text-blue-600, px-8 py-4, rounded-2xl, font-bold, hover:scale-105, shadow-lg
  - Includes hero-arrow-right icon

Right decoration:
- Absolute positioned, w-1/3, opacity-20
- hero-star icon: w-48 h-48 / lg:w-64 h-64

---

Goal Categories Section [IMPLEMENTED]

SectionHeader: title="Goal Categories", link_text="View All", link_to=/goals-category

Layout: Horizontal scroll row (flex gap-4, overflow-x-auto pb-4 custom-scrollbar)

Category pills:
- Data: @popular_groups (GoalCategory/Group records)
- Style: bg-white px-6 py-4 rounded-3xl soft-shadow border border-slate-50 min-w-fit
- Hover: hover:border-blue-200 transition-colors
- Icon: 48px rounded-2xl bg-blue-50 container with hero-fire w-6 h-6 text-blue-600
- Label: font-bold text-slate-700 text-base
- Link: /goals-category/:id

Empty state: Inline placeholder pill with bg-slate-50 icon + "No categories yet" text

---

Challenge Categories Section [IMPLEMENTED]

SectionHeader: title="Challenge Categories", link_text="View All", link_to=/challenges

Layout: Horizontal scroll row (same structure as Goal Categories)

Category pills:
- Data: @challenge_categories (ChallengeCategory records with status=active)
- Style: Same as Goal Categories but with indigo accent
- Hover: hover:border-indigo-200 transition-colors
- Icon: 48px rounded-2xl bg-indigo-50 container with hero-fire w-6 h-6 text-indigo-600
- Label: font-bold text-slate-700 text-base
- Link: /challenges?category=:id

Empty state: Inline placeholder pill with bg-slate-50 icon + "No categories yet" text

---

Top Goal-Setters Section [IMPLEMENTED]

Header: h2 "Top Goal-Setters" — text-2xl font-extrabold text-slate-900 mb-6
Layout: Horizontal scroll row (flex gap-6, overflow-x-auto pb-6 custom-scrollbar)

User items:
- Data: @user_spotlights (top 3 users by level)
- Layout: flex-col items-center, flex-shrink-0
- Avatar container: w-20 h-20 rounded-full p-1, border-2 border-blue-500 border-dashed
  - With image: 64px rounded-full object-cover
  - Without image: 64px gradient circle (from-blue-400 to-indigo-500) with uppercase initial
- Name: text-xs font-bold text-slate-900
- Link: /people/:username

Empty state: "No spotlight users yet" — text-sm text-slate-400 font-medium

---

Active Goals Feed Section [IMPLEMENTED]

Header row:
- Left: h2 "Active Goals" — text-2xl font-extrabold text-slate-900
- Right: Filter pills (Trending / Recent)
  - Trending: bg-slate-900 text-white px-6 py-2.5 rounded-xl text-sm font-bold → /all-goals
  - Recent: bg-white text-slate-500 soft-shadow, same sizing → /all-goals

Empty state:
- EmptyState component: icon="hero-fire", title="No active goals yet", message="Be the first to create a goal and start building momentum."
- Action slot: "Create Goal" blue gradient button → /goals/new

Goal cards:
- Data: @trending_goals (top 3 public goals by likes+subscriptions, preloaded with :user and :group)
- Wrapper: Card component with hover prop, entire card wrapped in .link to /goals/:id
- Card content:
  1. Post header: Avatar (size :lg) + user name (font-extrabold text-lg) + category name (text-slate-400 text-sm) + status badge (bg-indigo-50 text-indigo-600 rounded-full px-4 py-2)
  2. Goal title: text-xl font-extrabold text-slate-900
  3. Description: text-slate-600 text-lg leading-relaxed line-clamp-3
  4. Goal image (if present): w-full h-64 object-cover rounded-[32px]
  5. Progress bar: ProgressBar component (size :md, color :indigo, show_label true)
  6. Engagement row: heart icon + like count, eye icon + subscriber count, share icon + "Share" label, subscriber count bubble (ml-auto, -space-x-2)

---

Right Sidebar (Desktop Only)

Visibility: hidden xl:flex
Width: w-[420px] flex-shrink-0
Style: bg-white, border-l border-slate-100, p-8, overflow-y-auto custom-scrollbar
Gap: gap-10 between sections

Popular Groups:
- SectionHeader: title="Popular Groups", link_text="View all", link_to=/goals-category
- Layout: 2-column grid (grid-cols-2 gap-4)
- Group cards: bg-indigo-50 p-6 rounded-[32px], hover:scale-105, soft-shadow
  - 56px white circle icon container with hero-user-group text-blue-500
  - Group name: font-extrabold text-slate-900 text-sm
  - Goal count: text-[10px] text-slate-400
  - Link: /goals-category/:id
- Empty: "No groups yet" text

Suggestions:
- SectionHeader: title="Suggestions", link_text="See all", link_to=/people
- Layout: vertical stack (space-y-6)
- User rows: Avatar (size :lg) + name (font-bold text-sm) + "Level X" (text-slate-400 text-xs) + "Follow" button (bg-slate-900 text-white px-4 py-2.5 rounded-xl text-xs font-bold, hover:scale-105)
  - Follow link: /people/:username
- Empty: "No suggestions yet" text

Quick Stats:
- Header: h3 "Quick Stats" — text-2xl font-extrabold text-slate-900 mb-6
- Layout: vertical stack (space-y-4)
- Stat cards: p-5 bg-slate-50 rounded-2xl, flex items-center gap-4
  1. Trending Goals: blue icon (hero-fire, bg-blue-50), count from @trending_goals length
  2. Active Groups: indigo icon (hero-user-group, bg-indigo-50), count from @popular_groups length
  3. Top Users: purple icon (hero-users, bg-purple-50), count from @user_spotlights length
- Values: text-3xl font-extrabold text-slate-900
- Labels: text-xs text-slate-400 font-medium

---

States

Loading: Not yet implemented (skeleton components available for future use)
Empty: Per-section inline empty states:
  - Goal Categories: "No categories yet" placeholder pill
  - Challenge Categories: "No categories yet" placeholder pill
  - Top Goal-Setters: "No spotlight users yet" text
  - Active Goals: EmptyState component with "Create Goal" CTA
  - Right Sidebar Popular Groups: "No groups yet" text
  - Right Sidebar Suggestions: "No suggestions yet" text
Error: Not yet implemented (retry pattern available)

---

Personalization Rules [IMPLEMENTED]

Guest users:
- Left sidebar: Welcome card with "Get Started" CTA (instead of profile card)
- Hero CTA: "Get Started" → /users/register
- Mobile header: "Log in" text link + "Sign up" blue gradient pill
- Sidebar nav: Browse + Account (Log in / Register) only — no My Stuff, Coach, or Admin sections
- Drawer: Same sections as sidebar
- Bottom nav: "Login" label on last item → /users/log_in
- No promo card in sidebar or drawer
- See public goals only

Logged-in users:
- Left sidebar: Profile card with avatar, name, @username, green online dot
- Hero CTA: "Create Your Goal" → /goals/new
- Mobile header: "Create" button (blue gradient pill) → /goals/new
- Sidebar nav: Browse + My Stuff + Account (View Profile, Settings, Log out)
- Drawer: Same sections as sidebar + promo card
- Bottom nav: "Profile" label → /people/:username
- Promo card shown in sidebar and drawer

Coaches (coach/admin role):
- All logged-in features plus:
- Coach section in sidebar and drawer: Coach Center

Admins:
- All logged-in features plus:
- Admin section in sidebar and drawer: Goal Categories, Challenge Categories

---

Mobile Behavior [IMPLEMENTED]

Breakpoints:
- < lg (< 1024px): Single column, mobile header + drawer, bottom nav
- lg (1024px+): Left sidebar appears, mobile header/drawer/bottom nav hidden
- xl (1280px+): Right sidebar appears

Layout transitions:
- Left sidebar: hidden → lg:flex
- Right sidebar: hidden → xl:flex
- Mobile header: lg:hidden
- Bottom nav: lg:hidden
- Drawer: lg:hidden

Mobile-specific:
- Main content has pb-20 to account for fixed bottom nav
- Content padding: p-5 (mobile), sm:p-8 (tablet), lg:p-10 (desktop)
- Hero banner full width with stacked content
- Category pills horizontal scroll with snap
- Goal-setters horizontal scroll
- Goal cards full-width feed items
- "Create" label in mobile header hidden on xs, visible on sm (hidden sm:inline)

Bottom Navigation (BottomNav component):
- Fixed bottom, z-50, bg-white/95 backdrop-blur-lg
- 5 items:
  1. Home (hero-home) → /
  2. Explore (hero-magnifying-glass) → /all-goals
  3. Create (hero-plus-circle-solid, blue accent, larger icon) → /goals/new
  4. Challenges (hero-fire) → /challenges
  5. Profile/Login (hero-user) → /people/:username or /users/log_in

---

Data Dependencies

Controller assigns (PageController.home/2):

| Assign | Source | Query |
|---|---|---|
| @trending_goals | HeadsUp.Goal | Public goals ordered by (likes + subscriptions) count, limit 3, preload [:user, :group] |
| @popular_groups | HeadsUp.Group | Published groups ordered by goal count, limit 3; includes computed :goal_count |
| @user_spotlights | HeadsUp.Users | Users ordered by level desc, limit 3; includes computed :latest_achievement |
| @challenge_categories | HeadsUp.Challenges.ChallengeCategory | Active categories with template challenge count, ordered by :order then :name |
| @current_user | Session | Provided by auth pipeline in app layout |

Private helper functions:
- get_trending_goals/0 — Left join on GoalLike + GoalSubscription, group_by goal, order by combined count desc
- get_popular_groups/0 — Published groups with goal count, secondary query for exact count per group
- get_user_spotlights/0 — Top 3 by level, with latest completed goal title via get_user_latest_achievement/1
- get_challenge_categories/0 — Active categories with count of active template challenges
