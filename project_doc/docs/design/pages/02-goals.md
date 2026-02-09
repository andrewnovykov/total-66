Page: All Goals (Discover Goals)

Implementation Status: REDESIGNED (2026-02-06)
Design System: "Soft Modern" (ux-ui.md)

---

Basic Info
- URL: /all-goals
- LiveView: AllGoalsLive.Index
- Accessible by:
  - Guests
  - Logged-in Users
  - Coaches
  - Admins
- Purpose:
  Browse, search, and discover goals across the platform. Acts as the main goal directory with filtering by status and category.

---

Implementation Notes

Layout Type: Center feed + right sidebar (desktop); single column (mobile)
Background: Inherits app shell bg-[#F0F4FF]
Font: Plus Jakarta Sans (inherited from root layout)
Navigation: Uses app shell left sidebar (app.html.heex), not page-level nav

Reusable Components Used:
- HeadsUpWeb.Components.UI.Card - Goal feed cards (rounded-[40px], soft-shadow, hover variant)
- HeadsUpWeb.Components.UI.Avatar - Creator avatars with gradient initials fallback
- HeadsUpWeb.Components.UI.ProgressBar - Goal progress visualization (indigo color, size :md)
- HeadsUpWeb.Components.UI.SectionHeader - "Categories" section header with "View All" link
- HeadsUpWeb.Components.UI.EmptyState - Empty/no-results state with action slot

Custom CSS (inherited from root.html.heex):
- .custom-scrollbar - Thin 5px scrollbar
- .soft-shadow - Subtle box-shadow

---

Layout

Desktop Layout (lg: and above):

+------------------------------+-------------------+
| Center Content               | Right Sidebar     |
| flex-grow                    | w-[420px]         |
| p-5 / sm:p-8 / lg:p-10      | (hidden < xl)     |
+------------------------------+-------------------+
| Hero Banner + Search         | Quick Stats       |
| Category Pills               | Categories Grid   |
| Filter Pills + Results       | Create Goal Promo |
| Goals Feed                   |                   |
+------------------------------+-------------------+

Note: Left sidebar is provided by the app shell (app.html.heex), not by this page.

Mobile Layout (< lg):

+----------------------------------------+
| Center Content (full width, pb-20)     |
|  Hero+Search → Categories →            |
|  Filters → Goals Feed                  |
+----------------------------------------+

---

Hero Banner with Integrated Search [IMPLEMENTED]

Implementation: Blue gradient banner (from-blue-600 to-indigo-600), rounded-[40px], soft-shadow
Padding: p-8 / sm:p-10 / lg:p-12
Margin: mb-10

Left content (max-w-2xl, relative z-10):
- Badge: "Explore" — bg-blue-500/50 text-blue-100, text-xs font-bold, uppercase tracking-wider, rounded-full
- Headline: "Discover Goals" — text-3xl / sm:text-4xl / lg:text-5xl font-extrabold
- Subtext: "Browse goals from the community. Get inspired, follow progress, and find your next challenge." — text-blue-100, text-lg
- Search bar:
  - Container: bg-white/20 backdrop-blur-sm rounded-2xl border border-white/30
  - Icon: hero-magnifying-glass text-blue-200
  - Input: text-white placeholder-blue-200, phx-debounce="300", phx-change="search"
  - Clear button (x-mark icon) visible when search_query is not empty

Right decoration:
- Absolute positioned, w-1/3, opacity-20
- hero-flag icon: w-48 h-48 / lg:w-64 h-64

---

Category Pills Section [IMPLEMENTED]

Visibility: Only shown when categories exist
SectionHeader: title="Categories", link_text="View All", link_to=/goals-category

Layout: Horizontal scroll row (flex gap-3, overflow-x-auto pb-4 custom-scrollbar)

Pills:
- "All" button: Always first, resets category filter
- Category buttons: One per published group/category (limit 20)
- Active state: bg-slate-900 text-white border-slate-900
- Inactive state: bg-white text-slate-500 border-slate-100 soft-shadow hover:border-blue-200
- Style: px-5 py-3 rounded-2xl font-bold text-sm min-w-fit

Behavior:
- Clicking a category toggles it (click again to deselect)
- Clicking "All" resets to no category filter
- Filters combine with search and status filter

---

Filter Pills + Results Header [IMPLEMENTED]

Header row (flex items-center justify-between mb-8):
- Left:
  - Title: "All Goals" or "Results for '{query}'" — text-2xl font-extrabold text-slate-900
  - Count: "{N} goals found" — text-slate-400 text-sm font-medium mt-1
- Right: Status filter pills
  - All: Default active
  - Active: Filter to status == :active
  - Completed: Filter to status == :completed (hidden sm:block on mobile)
  - Active pill: bg-slate-900 text-white
  - Inactive pill: bg-white text-slate-500 soft-shadow
  - Style: px-6 py-2.5 rounded-xl text-sm font-bold

---

Goals Feed [IMPLEMENTED]

Feed-style goal cards (vertical stack, space-y-6):

Viewable Goals (public, or authorized private/friends):
- Wrapper: Card component with hover prop, entire card wrapped in .link to /goals/:id
- Card content (identical to home page Active Goals feed):
  1. Post header: Avatar (size :lg) + user name (font-extrabold text-lg) + category name (text-slate-400 text-sm) + status badge (bg-indigo-50 text-indigo-600 rounded-full px-4 py-2)
  2. Goal title: text-xl font-extrabold text-slate-900
  3. Description: text-slate-600 text-lg leading-relaxed line-clamp-3
  4. Goal image (if present): w-full h-64 object-cover rounded-[32px]
  5. Progress bar: ProgressBar component (size :md, color :indigo, show_label true)
  6. Engagement row: heart icon + like count, eye icon + subscriber count, share icon + "Share", subscriber bubble (ml-auto)

Restricted Goals (private/friends-only, unauthorized viewer):
- Card component (no hover, no link)
- Compact layout: lock icon (w-14 h-14 rounded-full bg-slate-100) + title ("Private Goal" / "Friends Only") + description + privacy badge (bg-slate-100 text-slate-500 rounded-full)

---

Right Sidebar (Desktop Only)

Visibility: hidden xl:flex
Width: w-[420px] flex-shrink-0
Style: bg-white, border-l border-slate-100, p-8, overflow-y-auto custom-scrollbar
Gap: gap-10 between sections

Quick Stats:
- Header: h3 "Quick Stats" — text-2xl font-extrabold text-slate-900 mb-6
- Layout: vertical stack (space-y-4)
- Stat cards: p-5 bg-slate-50 rounded-2xl, flex items-center gap-4
  1. Total Goals: blue icon (hero-flag, bg-blue-50), count from @all_goals length
  2. Active Goals: green icon (hero-check-circle, bg-green-50), count of active status
  3. Completed: indigo icon (hero-trophy, bg-indigo-50), count of completed status
- Values: text-3xl font-extrabold text-slate-900
- Labels: text-xs text-slate-400 font-medium

Categories Grid:
- SectionHeader: title="Categories", link_text="View all", link_to=/goals-category
- Layout: 2-column grid (grid-cols-2 gap-4), limit 6 shown
- Category cards: p-6 rounded-[32px], hover:scale-105, soft-shadow
  - Default: bg-indigo-50
  - Active filter: bg-blue-50 ring-2 ring-blue-500
  - 56px white circle icon (hero-flag text-blue-500)
  - Category name: font-extrabold text-slate-900 text-sm
  - Clickable: phx-click="filter_category" — same toggle behavior as center pills
- Empty: "No categories yet" text

Create Goal Promo (logged-in only):
- bg-gradient-to-br from-blue-600 to-indigo-700 rounded-3xl p-6
- shadow-lg shadow-blue-500/20
- "Create a Goal" title + "Track progress & build momentum" subtitle
- "New Goal" white CTA button → /goals/new
- Decorative hero-rocket-launch icon (opacity-20, bottom-right)

---

States

Empty (no goals):
- EmptyState component: icon="hero-flag", title="No goals yet", message="Be the first to create a goal..."
- Action: "Create Goal" blue gradient button → /goals/new

No Search Results:
- EmptyState component: icon="hero-flag", title="No goals match your search", message="Try adjusting your search terms..."
- Action: "Clear Search" blue gradient button → resets search

Loading: Not yet implemented (skeleton components available)
Error: Not yet implemented

---

Search & Filter Behavior [IMPLEMENTED]

Three independent filters that combine:
1. **Search** (text): Matches against goal title, description, category name, user name (case-insensitive)
2. **Status** (pills): All / Active / Completed / Paused
3. **Category** (pills + sidebar grid): Toggle individual categories

All filtering is client-side (in-memory on @all_goals assign).
Search uses phx-debounce="300" for performance.

Privacy Rules:
- can_view_goal?/2 checks privacy per goal
- Public: visible to all
- Private: visible only to owner
- Friends-only: visible to owner and accepted friends
- Non-viewable goals show restricted placeholder card

---

Personalization Rules [IMPLEMENTED]

Guest users:
- See all public goals
- Private/friends-only goals show restricted card
- No promo card in sidebar
- Can search and filter

Logged-in users:
- See public goals + own private goals + friends' friends-only goals
- "Create Goal" promo in right sidebar
- Can search and filter

---

Mobile Behavior [IMPLEMENTED]

Breakpoints:
- < lg: Single column, no sidebar
- lg+: Left sidebar from app shell
- xl+: Right sidebar appears

Mobile-specific:
- Content padding: p-5 (mobile), sm:p-8 (tablet), lg:p-10 (desktop)
- Hero with search full width
- Category pills horizontal scroll
- "Completed" filter pill hidden on xs (hidden sm:block)
- Goal cards full-width feed items
- Right sidebar content not visible (stats, categories, promo hidden)

---

Data Dependencies

LiveView assigns (AllGoalsLive.Index.mount/3):

| Assign | Source | Query |
|---|---|---|
| @all_goals | Goals.list_goals() | All goals, preloaded [:group, :user, :goal_likes, :goal_subscriptions], with social counts |
| @filtered_goals | Derived | @all_goals filtered by search + status + category |
| @search_query | User input | Current search text |
| @active_filter | User input | "all" / "active" / "completed" / "paused" |
| @active_category | User input | Category ID or nil |
| @categories | HeadsUp.Group | Published groups ordered by name, limit 20 |
| @current_user | Session | From socket assigns |
| @current_user_id | Derived | current_user.id or nil |

LiveView events:
- "search" %{"query" => ...} — Update search filter
- "filter" %{"filter" => ...} — Update status filter
- "filter_category" %{"category-id" => "0"} — Reset category (All)
- "filter_category" %{"category-id" => id} — Toggle category filter

---

Related Pages
- Home → / (Active Goals feed links here via "Trending" pill)
- Goal Detail → /goals/:id
- My Goals → /my-goals
- Create Goal → /goals/new
- Goal Categories → /goals-category
