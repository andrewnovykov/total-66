Page: Goal Categories (Groups)

Implementation Status: REDESIGNED (2026-02-06)
Design System: "Soft Modern" (ux-ui.md)

---

Basic Info — Index Page
- URL: /goals-category
- LiveView: GoalCategoryLive.Index
- Accessible by:
  - Guests
  - Logged-in Users
  - Coaches
  - Admins
- Purpose:
  Browse goal categories (groups) and discover goals organized by theme.

Basic Info — Show Page
- URL: /goals-category/:id
- LiveView: GoalCategoryLive.Show
- Accessible by: Same as Index
- Purpose:
  View a single category with its goals, filter by status, and engage with goals.

---

Implementation Notes

Layout Type: Center feed + right sidebar (desktop); single column (mobile)
Background: Inherits app shell bg-[#F0F4FF]
Font: Plus Jakarta Sans (inherited from root layout)
Navigation: Uses app shell left sidebar (app.html.heex)

Reusable Components Used:
- HeadsUpWeb.Components.UI.Card - Category cards and goal feed cards (rounded-[40px], soft-shadow, hover variant)
- HeadsUpWeb.Components.UI.Avatar - Creator avatars in goal cards
- HeadsUpWeb.Components.UI.ProgressBar - Goal progress (indigo, size :md)
- HeadsUpWeb.Components.UI.SectionHeader - Section headers with optional links
- HeadsUpWeb.Components.UI.EmptyState - Empty/no-results states with action slots

---

INDEX PAGE: /goals-category

Layout

Desktop (xl+):

+------------------------------+-------------------+
| Center Content               | Right Sidebar     |
| flex-grow                    | w-[420px]         |
| p-5 / sm:p-8 / lg:p-10      | (hidden < xl)     |
+------------------------------+-------------------+
| Hero Banner + Search         | Overview Stats    |
| Results Header + Admin CTA   | Most Active       |
| Categories Grid              | Create Goal Promo |
+------------------------------+-------------------+

---

Hero Banner with Search [IMPLEMENTED]

Implementation: Blue gradient (from-blue-600 to-indigo-600), rounded-[40px], soft-shadow
Padding: p-8 / sm:p-10 / lg:p-12

Content:
- Badge: "Browse" — bg-blue-500/50 text-blue-100, uppercase tracking-wider
- Headline: "Goal Categories" — text-3xl / sm:text-4xl / lg:text-5xl font-extrabold
- Subtext: "Explore categories and discover goals organized by theme." — text-blue-100 text-lg
- Search bar: Same style as all-goals page (bg-white/20 backdrop-blur-sm rounded-2xl, hero-magnifying-glass icon, phx-debounce="300")
- Decoration: hero-squares-2x2 icon (opacity-20, absolute right)

---

Results Header [IMPLEMENTED]

- Title: "All Categories" or "Results for '{query}'" — text-2xl font-extrabold
- Count: "{N} categories" — text-slate-400 text-sm
- Admin CTA (admin only): "Manage Categories" blue gradient button → /admin/categories

---

Categories Grid [IMPLEMENTED]

Layout: Responsive grid (grid-cols-1 / sm:grid-cols-2 / xl:grid-cols-3 gap-6)

Category Cards:
- Card component with hover
- Image section: -mx-8 -mt-8 mb-6 (bleeds to card edges)
  - With image: h-48 object-cover rounded-t-[40px]
  - Without image: gradient placeholder (from-blue-400 to-indigo-500) with white initial circle
- Category name: text-xl font-extrabold text-slate-900
- Description: text-slate-500 text-base line-clamp-2
- Stats row: Two pastel badges
  - Total goals: bg-blue-50 text-blue-600 with hero-flag icon
  - Active goals: bg-green-50 text-green-600 with hero-check-circle icon
- Click: Navigates to /goals-category/:id

Empty state:
- EmptyState component: icon="hero-squares-2x2"
- Search mode: "No categories match your search" + "Clear Search" CTA
- Default: "No categories yet" + "Categories will appear here once an admin creates them."

---

Right Sidebar — Index Page

Overview Stats:
- Total Categories count (hero-squares-2x2, bg-blue-50)
- Total Goals sum (hero-flag, bg-indigo-50)
- Active Goals sum (hero-check-circle, bg-green-50)

Most Active:
- SectionHeader: "Most Active" (no link)
- Top 5 categories sorted by active_goal_amount desc
- Rows: category image/initial (w-12 rounded-xl) + name + active count + chevron-right
- Clickable → navigates to category

Create Goal Promo (logged-in only):
- Standard promo card (from-blue-600 to-indigo-700, rocket-launch icon)

---

SHOW PAGE: /goals-category/:id

Layout

Desktop (xl+):

+------------------------------+-------------------+
| Center Content               | Right Sidebar     |
+------------------------------+-------------------+
| Hero Banner (category info)  | Category Stats    |
| Filter Pills + Results       | Browse Links      |
| Goals Feed                   | Create Goal Promo |
+------------------------------+-------------------+

---

Hero Banner with Category Info [IMPLEMENTED]

Implementation: Blue gradient, rounded-[40px], soft-shadow

Content:
- Back link: "All Categories" — text-blue-200 hover:text-white, hero-arrow-left icon → /goals-category
- Layout: flex items-start gap-6
- Category image: w-20/sm:w-24 rounded-2xl, border-4 border-white/20 (or initial placeholder)
- Category name: text-3xl / sm:text-4xl font-extrabold
- Description: text-blue-100 text-lg
- Stats badges: Two bg-white/20 backdrop-blur-sm pills (total goals, active goals)
- Decoration: hero-user-group icon (opacity-10)

---

Filter Pills [IMPLEMENTED]

Header row:
- Title: "Goals" — text-2xl font-extrabold
- Count: "{N} goals in this category" — text-slate-400 text-sm
- Status filter pills: All / Active / Completed (Completed hidden on mobile)
  - Active: bg-slate-900 text-white
  - Inactive: bg-white text-slate-500 soft-shadow
  - Style: px-6 py-2.5 rounded-xl text-sm font-bold

Filtering is client-side on @all_goals.

---

Goals Feed [IMPLEMENTED]

Identical to all-goals page feed cards:
- Card with hover, linked to /goals/:id
- Post header: Avatar + user name + category name + status badge
- Goal title + description (line-clamp-3) + optional image (rounded-[32px])
- ProgressBar (indigo, :md)
- Engagement row: heart + eye + share + subscriber bubble

Restricted goals: Lock icon card with privacy label.

Empty state: EmptyState with "Create Goal" CTA.

---

Right Sidebar — Show Page

Category Stats:
- Total Goals (hero-flag, bg-blue-50)
- Active Goals (hero-check-circle, bg-green-50)
- Currently Showing (hero-users, bg-indigo-50) — count of @all_goals

Browse:
- SectionHeader: "Browse" with "All Categories" link → /goals-category
- Navigation rows:
  - "All Goals" → /all-goals (hero-fire, bg-blue-50)
  - "All Categories" → /goals-category (hero-squares-2x2, bg-indigo-50)

Create Goal Promo (logged-in only):
- Standard promo card

---

States

Index — Empty:
- EmptyState with search-aware title/message
- "Clear Search" CTA when searching

Index — Search mode:
- Title changes to "Results for '{query}'"
- Count updates in real-time

Show — Empty (no goals in category):
- EmptyState: "No goals found" + "Create Goal" CTA

Show — Filter empty:
- Same EmptyState with filter-aware message

---

Personalization Rules

Guest:
- Can browse all categories and public goals
- No promo card in sidebar
- Restricted goals show lock icon card

Admin:
- "Manage Categories" button in index results header → /admin/categories

Logged-in:
- Create Goal promo in sidebar
- Can see own private goals and friends' goals

---

Mobile Behavior

Breakpoints:
- < lg: Single column, no sidebars
- lg+: Left sidebar (app shell)
- xl+: Right sidebar appears

Mobile-specific:
- Content padding: p-5 / sm:p-8 / lg:p-10
- Category grid: single column on mobile, 2-col on sm
- "Completed" filter pill hidden on mobile (hidden sm:block)
- Hero banner full width, category image stacks with text
- Goal cards full-width feed items

---

Data Dependencies

Index assigns:
| Assign | Source |
|---|---|
| @groups | Groups.list_published_groups() with goal counts |
| @filtered_groups | @groups filtered by search query |
| @search_query | User input |

Show assigns:
| Assign | Source |
|---|---|
| @group | Groups.get_group!/1 with total/active goal counts |
| @all_goals | Goals.list_goals_by_group/1, preloaded [:user, :group, :goal_likes, :goal_subscriptions], with social counts |
| @goals | @all_goals filtered by status |
| @filter_status | "all" / "active" / "completed" / "paused" |
| @current_user_id | current_user.id or nil |

Show events:
- "filter_status" %{"status" => ...} — Filter goals by status
- "toggle_like" %{"goal-id" => ...} — Like/unlike a goal (logged-in only)
- "toggle_subscribe" %{"goal-id" => ...} — Subscribe/unsubscribe (logged-in only)

---

Related Pages
- Home → / (Goal Categories section links here)
- All Goals → /all-goals (Category filter references these)
- Goal Detail → /goals/:id
- Create Goal → /goals/new
- Admin Categories → /admin/categories
