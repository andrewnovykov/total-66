Page: My Goals

Implementation Status: REDESIGNED (2026-02-06)
Design System: "Soft Modern" (ux-ui.md)

---

Basic Info
- URL: /my-goals
- LiveView: MyGoalsLive.Index
- Accessible by:
  - Logged-in Users
  - Coaches
  - Admins
- Purpose:
  Personal dashboard for managing all of a user's goals. Shows active/completed/paused goals with progress, subscription info, and quick actions.

---

Implementation Notes

Layout Type: Center feed + right sidebar (desktop); single column (mobile)
Background: Inherits app shell bg-[#F0F4FF]
Font: Plus Jakarta Sans (inherited from root layout)
Navigation: Uses app shell left sidebar (app.html.heex)

Reusable Components Used:
- HeadsUpWeb.Components.UI.Card - Goal cards (rounded-[40px], soft-shadow, hover variant)
- HeadsUpWeb.Components.UI.StatusBadge - Goal status (size :sm)
- HeadsUpWeb.Components.UI.ProgressBar - Goal progress (indigo, size :md)
- HeadsUpWeb.Components.UI.EmptyState - Empty/filtered-empty states with action slots

---

Layout

Desktop (xl+):

+------------------------------+-------------------+
| Center Content               | Right Sidebar     |
| flex-grow                    | w-[420px]         |
| p-5 / sm:p-8 / lg:p-10      | (hidden < xl)     |
+------------------------------+-------------------+
| Hero Banner + Create CTA     | Overview Stats    |
| Filter Pills + Results       | Subscription Info |
| Goals Feed (cards)           | Quick Links       |
| Deleted Goals (collapsible)  | Create Goal Promo |
+------------------------------+-------------------+

---

Hero Banner [IMPLEMENTED]

Implementation: Blue gradient (from-blue-600 to-indigo-600), rounded-[40px], soft-shadow
Padding: p-8 / sm:p-10 / lg:p-12

Content:
- Badge: "Dashboard" — bg-blue-500/50 text-blue-100, uppercase tracking-wider
- Headline: "My Goals" — text-3xl / sm:text-4xl / lg:text-5xl font-extrabold
- Subscription info: "{N} of {limit} goals used · {subscription name}" — text-blue-100 text-lg
- Create Goal CTA:
  - Enabled: bg-white text-blue-600 px-8 py-4 rounded-2xl, hover:scale-105 transition
  - Disabled: bg-white/30 text-white/70, cursor-not-allowed, phx-click="show_upgrade_message"
- Decoration: hero-flag icon (opacity-10, absolute right)

---

Filter Pills [IMPLEMENTED]

Header row:
- Title: Dynamic based on filter ("All Goals" / "Active Goals" / etc.) — text-2xl font-extrabold
- Count: "{N} goals" — text-slate-400 text-sm
- Filter pills: All / Active / Completed (Completed hidden on mobile)
  - Active: bg-slate-900 text-white
  - Inactive: bg-white text-slate-500 soft-shadow
  - Style: px-6 py-2.5 rounded-xl text-sm font-bold
  - Each shows count in parentheses: "All (3)"

---

Goals Feed [IMPLEMENTED]

Feed-style layout (space-y-6), each goal is a Card with hover.

Goal Cards:
- Card component with hover, wrapped in .link to /goals/:id
- Layout: flex flex-col sm:flex-row gap-6
- Image: w-full sm:w-40 h-40 sm:h-32 rounded-2xl (or gradient placeholder with hero-flag)
- Content:
  - Badges row: StatusBadge (:sm) + privacy badge (bg-slate-100, icon + label) + category badge (bg-blue-50)
  - Title: text-lg font-extrabold line-clamp-1
  - Description: text-slate-500 text-sm line-clamp-2
  - Progress: ProgressBar (indigo, :md) + percentage + target date (hidden on mobile)
- Link class: block cursor-pointer hover:shadow-lg transition-all

Empty state: EmptyState component with filter-aware title/message, "Create Goal" CTA when filter=all.

---

Deleted Goals Section [IMPLEMENTED]

Shown below goals feed when user has deleted goals.

Header:
- Title: "Deleted Goals" — text-xl font-extrabold
- Count: "{N} deleted goals" — text-slate-400 text-sm
- Toggle button: bg-slate-100 rounded-xl, hero-eye / hero-eye-slash icons

Deleted Goal Cards (when expanded):
- bg-slate-50 rounded-[40px] p-8, border border-slate-100, opacity-75
- Layout: flex flex-col sm:flex-row gap-6
- Image: grayscale (or slate gradient with hero-trash)
- Content: "Deleted" badge (bg-red-50 text-red-600), title, description, deletion date
- Restore button: bg-gradient-to-r from-green-500 to-emerald-600, hero-arrow-path icon

---

Right Sidebar (Desktop Only)

Visibility: hidden xl:flex
Width: w-[420px] flex-shrink-0
Style: bg-white, border-l border-slate-100, p-8, overflow-y-auto custom-scrollbar
Gap: gap-10 between sections

Overview Stats:
- Total Goals (hero-flag, bg-blue-50)
- Active count (hero-check-circle, bg-green-50)
- Completed count (hero-trophy, bg-indigo-50)

Subscription Info:
- Gradient card (from-blue-500 to-indigo-600)
- Plan name, usage progress bar (bg-white/20 track, bg-white fill)
- Usage count: "{current} / {limit}"

Quick Links:
- Browse All Goals → /all-goals (hero-fire, bg-blue-50)
- Goal Categories → /goals-category (hero-squares-2x2, bg-indigo-50)

Create Goal Promo (when under limit):
- Gradient card (from-blue-600 to-indigo-700)
- hero-rocket-launch icon, "Ready for a new goal?" text, "Create Goal" button

---

States

Empty (no goals):
- EmptyState: icon="hero-flag", "No goals yet", "Create Goal" CTA

Filter empty:
- EmptyState: "No {status} goals", "Show All Goals" button

Limit reached:
- Hero create button becomes disabled (bg-white/30)
- Flash message on mount about subscription limit
- show_upgrade_message event on disabled button click

---

Personalization Rules

Subscription types:
- Free (1 goal): "0 of 1 goals used · Free (1 goal)"
- Pro (3 goals): "0 of 3 goals used · Pro (3 goals)"
- Premium (Unlimited): "0 of unlimited goals used · Premium (Unlimited goals)"

Create button behavior:
- Under limit: Shows link to /goals/new
- At/over limit: Shows disabled button with phx-click="show_upgrade_message"

---

Mobile Behavior

Breakpoints:
- < lg: Single column, no sidebars
- lg+: Left sidebar (app shell)
- xl+: Right sidebar appears

Mobile-specific:
- Content padding: p-5 (mobile), sm:p-8 (tablet), lg:p-10 (desktop)
- Goal cards: Image stacks above content (flex-col)
- "Completed" filter pill hidden on mobile (hidden sm:block)
- Target date hidden on mobile (hidden sm:inline)
- Right sidebar hidden

---

Data Dependencies

LiveView assigns (MyGoalsLive.Index.mount/3):

| Assign | Source |
|---|---|
| @my_goals | Goals.list_goals_by_user(current_user_id) |
| @deleted_goals | Goals.list_deleted_goals_by_user(current_user_id) |
| @current_user_id | current_user.id |
| @show_deleted | false |
| @filter_status | "all" |
| @current_user | socket.assigns.current_user |

Computed in render:
| Assign | Source |
|---|---|
| @displayed_goals | @my_goals filtered by @filter_status |
| @counts | Map of %{all:, active:, completed:, paused:} |

Events:
- "filter_status" %{"status" => ...} — Filter goals by status
- "show_upgrade_message" — Show flash when at goal limit
- "toggle_deleted_goals" — Show/hide deleted goals section
- "restore_goal" %{"goal-id" => ...} — Restore a deleted goal

---

Related Pages
- Create Goal → /goals/new
- Goal Detail → /goals/:id
- Edit Goal → /goals/:id/edit
- All Goals → /all-goals
- Goal Categories → /goals-category
