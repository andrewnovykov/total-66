Page: Goal Detail

Implementation Status: REDESIGNED (2026-02-06)
Design System: "Soft Modern" (ux-ui.md)

---

Basic Info
- URL: /goals/:id
- LiveView: GoalLive.Show
- Accessible by:
  - Goal owner (full edit access)
  - Public goal viewers (read-only)
  - Friends-only goal viewers (if friends)
  - Private goal: owner only (others redirected)
- Purpose:
  Show full details of a single goal: progress, steps, activity feed, and social interaction.

---

Implementation Notes

Layout Type: Center feed + right sidebar (desktop); single column (mobile)
Background: Inherits app shell bg-[#F0F4FF]
Font: Plus Jakarta Sans (inherited from root layout)
Navigation: Uses app shell left sidebar (app.html.heex)

Reusable Components Used:
- HeadsUpWeb.Components.UI.Card - Content sections (rounded-[40px], soft-shadow)
- HeadsUpWeb.Components.UI.Avatar - Creator avatar in sidebar, post avatars in feed
- HeadsUpWeb.Components.UI.ProgressBar - Goal progress (indigo, size :lg, show_label)
- HeadsUpWeb.Components.UI.StatusBadge - Goal status in hero (size :md)
- HeadsUpWeb.Components.UI.EmptyState - Empty feed state

---

Layout

Desktop (xl+):

+------------------------------+-------------------+
| Center Content               | Right Sidebar     |
| flex-grow                    | w-[420px]         |
| p-5 / sm:p-8 / lg:p-10      | (hidden < xl)     |
+------------------------------+-------------------+
| Hero Banner (goal info)      | Goal Info Stats   |
| Image Edit (if editing)      | Creator Card      |
| Progress Card                | Support Actions   |
| About This Goal Card         | Timeline          |
| Goal Steps Card              |                   |
| Goal Management (owner)      |                   |
| Share Update (owner)         |                   |
| Goal Feed (posts)            |                   |
+------------------------------+-------------------+

---

Hero Banner [IMPLEMENTED]

Implementation: Blue gradient (from-blue-600 to-indigo-600), rounded-[40px], soft-shadow
Padding: p-8 / sm:p-10 / lg:p-12

Content:
- Back link: Category name — text-blue-200 hover:text-white, hero-arrow-left icon
- Layout: flex flex-col sm:flex-row gap-6
- Goal image: w-24/sm:w-28 rounded-2xl, border-4 border-white/20 (or flag icon placeholder)
  - Owner: Camera button (absolute bottom-right) to edit image
- Title: text-2xl / sm:text-3xl / lg:text-4xl font-extrabold (editable by owner via pencil icon)
- Badges row: StatusBadge + privacy badge (bg-white/20) + category link badge (bg-white/20)
- Engagement stats: likes, subscribers, posts count — text-blue-100 text-sm

Decoration: hero-flag icon (opacity-10, absolute right)

---

Image Edit Section [IMPLEMENTED]

Shown below hero when @editing_image is true.
Card component with:
- URL input (bg-slate-50 rounded-xl)
- Image preview
- Update / Cancel / Remove buttons

---

Progress Card [IMPLEMENTED]

Card component containing:
- ProgressBar (color: :indigo, size: :lg, show_label: true)
- Shows "Goal Progress" label and percentage

---

About This Goal Card [IMPLEMENTED]

Card component with:
- Title: "About This Goal" — text-xl font-extrabold
- Short description: text-slate-500, editable by owner (Add/Edit button)
- Big description: prose text-slate-600, editable by owner
- Edit forms: textarea with bg-slate-50, rounded-xl, no border

---

Goal Steps Card [IMPLEMENTED]

Card component with:
- Title: "Goal Steps" + completion count (X/Y completed)
- Add step form (owner only, max 10): bg-slate-50 input + gradient Add Step button
- Steps list: space-y-3
  - Each step: bg-slate-50 rounded-2xl p-4
  - Checkbox: w-6 h-6 rounded-lg (green when completed, interactive for owner)
  - Title: font-medium, line-through when completed
  - Edit/Delete buttons (owner only): pencil-square and trash icons

---

Goal Management Card [IMPLEMENTED]

Owner-only section with Card component:
- Title: "Goal Management" — text-xl font-extrabold
- Action buttons (flex-wrap gap-3):
  - Freeze/Unfreeze: purple/green rounded-xl
  - Edit Goal Details: blue gradient
  - Fail Goal: amber (opens modal)
  - Delete Goal: red with data-confirm
- Status notices: purple-50 or amber-50 rounded-2xl

---

Share Update Card [IMPLEMENTED]

Owner-only, hidden when goal is frozen/failed/deleted.
Card component with:
- Title: "Share an Update"
- Textarea: bg-slate-50 rounded-xl, 1000 char max
- Post type select: Update / Achievement / Milestone / Challenge / Motivation
- Related step select: General or specific step
- Submit: gradient button, disabled when empty

---

Goal Feed [IMPLEMENTED]

Section title: "Goal Feed" — text-2xl font-extrabold

Post cards (Card component, space-y-6):
- Post header: Avatar (size :lg) + user name (font-extrabold) + post type badge + timestamp
  - Post type badges: colored pastel pills (blue/green/amber/red/purple)
  - Author edit/delete buttons (pencil-square, trash icons)
- Step reference: clipboard icon + step title (if related to a step)
- Post content: text-slate-700, text-base, editable if own post
- Post image: rounded-[32px] (if present)
- Engagement row: heart icon + like count, chat icon + comment count
  - Like: interactive for non-authors (red when liked, hero-heart-solid)
  - Comments: collapsible section
- Comments section (expanded):
  - Comment cards: bg-slate-50 rounded-xl, gradient avatar initial, name, date, content
  - Delete own comments (x-mark icon)
  - Add comment form: bg-slate-50 input + gradient Post button

Empty state: EmptyState component, icon="hero-chat-bubble-left-right", "No posts yet"

---

Right Sidebar (Desktop Only)

Visibility: hidden xl:flex
Width: w-[420px] flex-shrink-0
Style: bg-white, border-l border-slate-100, p-8, overflow-y-auto custom-scrollbar
Gap: gap-10 between sections

Goal Info:
- Header: "Goal Info" — text-2xl font-extrabold
- Stat cards (p-5 bg-slate-50 rounded-2xl, icon in colored square):
  - Target Date (hero-calendar, bg-blue-50)
  - Steps Completed X/Y (hero-clipboard-document-list, bg-indigo-50)
  - Progress % (hero-chart-bar, bg-green-50)

Creator:
- Header: "Creator" — text-2xl font-extrabold
- Card: bg-slate-50 rounded-2xl, Avatar (size :xl) + name + @username
- Bio text (if present)
- Stats grid: Level + Goals count in white rounded-xl cards

Support:
- Header: "Support" — text-2xl font-extrabold
- Owner view: Like count + Subscriber count (static stat cards)
- Non-owner view: Interactive Like/Subscribe buttons (full-width, bg-red-50/bg-blue-50)
  - Toggle states: filled icons when active

Timeline:
- Header: "Timeline" — text-2xl font-extrabold
- Vertical dot timeline:
  - Goal Created (blue dot) + date
  - Last Updated (green dot) + date
  - Goal Failed (red dot) + date + failure reason card (bg-red-50 rounded-xl)

---

States

Empty Feed:
- EmptyState: icon="hero-chat-bubble-left-right", title="No posts yet"

Empty Steps:
- Centered: clipboard icon in slate-100 circle + "No steps added yet."

Permission Error:
- Flash message + redirect to /goals

Goal Not Found:
- Flash message + redirect to /goals

---

Personalization Rules

Guest:
- Can view public goals (read-only)
- No like/subscribe/comment buttons
- No edit controls

Logged-in (non-owner):
- Like/subscribe buttons visible
- Can comment on posts
- Can like others' posts
- No edit controls for goal/steps

Owner:
- Full edit access: title, description, big_description, image
- Step management: add, toggle, edit, delete
- Goal management: freeze/unfreeze, edit, fail, delete
- Post composer visible
- Edit/delete own posts

---

Mobile Behavior

Breakpoints:
- < lg: Single column, no sidebars
- lg+: Left sidebar (app shell)
- xl+: Right sidebar appears

Mobile-specific:
- Content padding: p-5 (mobile), sm:p-8 (tablet), lg:p-10 (desktop)
- Hero banner: goal image and text stack vertically
- Right sidebar content hidden (goal info, creator, support, timeline)
- Steps and posts full-width cards

---

Failure Modal

Overlay: bg-black/50 backdrop-blur-sm, z-50
Modal: bg-white rounded-[32px] shadow-2xl max-w-md p-8
Content:
- Amber icon + title "Mark Goal as Failed"
- Textarea for failure reason (500 char max)
- Cancel + Mark as Failed buttons

---

Data Dependencies

LiveView assigns (GoalLive.Show.mount/3):

| Assign | Source |
|---|---|
| @goal | Goals.get_goal_with_post_likes!/2 (preloads: group, user, goal_steps, goal_posts with users, goal_likes, goal_subscriptions) |
| @current_user_id | current_user.id or nil |
| @is_owner | current_user && goal.user_id == current_user.id |
| @user_liked | Goals.user_liked_goal?/2 |
| @user_subscribed | Goals.user_subscribed_to_goal?/2 |
| @new_step_title | "" |
| @editing_step_id | nil |
| @editing_title | false |
| @editing_description | false |
| @editing_big_description | false |
| @editing_image | false |
| @post_content | "" |
| @post_type | :update |
| @post_step_id | nil |
| @editing_post_id | nil |
| @show_fail_modal | false |
| @failure_reason | "" |
| @expanded_comments | MapSet.new() |

Events:
- toggle_like — Like/unlike goal
- toggle_subscribe — Subscribe/unsubscribe
- add_step — Add new step
- toggle_step — Complete/uncomplete step
- edit_step / update_step / cancel_edit — Step editing
- delete_step — Remove step
- edit_title / update_title / cancel_edit_title — Title editing
- edit_description / update_description / cancel_edit_description — Description editing
- edit_big_description / update_big_description / cancel_edit_big_description — Big description editing
- edit_goal_image / update_goal_image / cancel_edit_image / remove_goal_image — Image editing
- create_post — Create new post
- edit_post / update_post / cancel_edit_post / delete_post — Post editing
- toggle_post_like — Like/unlike post
- toggle_comments — Expand/collapse comments
- add_comment / delete_comment — Comment management
- freeze_goal / unfreeze_goal — Status changes
- show_fail_modal / hide_fail_modal / fail_goal — Fail flow
- edit_goal — Navigate to edit page
- delete_goal — Soft delete

---

Related Pages
- All Goals → /all-goals
- My Goals → /my-goals
- Goal Categories → /goals-category
- Category Detail → /goals-category/:id
- Edit Goal → /goals/:id/edit
