# Plan: Remove Goals & Groups from Total 66

## Context
Total 66 is a **new project** (66-day challenge platform), not HeadsUp. The codebase was bootstrapped from HeadsUp but goals and goal groups are not part of Total 66. We need to surgically remove all goal/group code while keeping: challenges, social features, auth, gamification, messaging, and reporting (for users/challenges only).

---

## Phase 1: Delete Goal/Group Files (~51 files)

### Schemas (8 files)
```
rm lib/heads_up/goal.ex
rm lib/heads_up/goal_step.ex
rm lib/heads_up/goal_like.ex
rm lib/heads_up/goal_subscription.ex
rm lib/heads_up/goal_post_like.ex
rm lib/heads_up/goals/goal_post.ex
rm lib/heads_up/goals/goal_comment.ex
rm lib/heads_up/group.ex
```

### Contexts (3 files)
```
rm lib/heads_up/goals.ex
rm lib/heads_up/groups.ex
rm lib/heads_up/goal_groups.ex
```

### LiveViews (5 directories)
```
rm -rf lib/heads_up_web/live/goal_live/
rm -rf lib/heads_up_web/live/my_goals_live/
rm -rf lib/heads_up_web/live/all_goals_live/
rm -rf lib/heads_up_web/live/goal_category_live/
rm -rf lib/heads_up_web/live/admin/groups_live/
```

### API Controllers (5 files)
```
rm lib/heads_up_web/controllers/api/goal_controller.ex
rm lib/heads_up_web/controllers/api/goal_step_controller.ex
rm lib/heads_up_web/controllers/api/goal_post_controller.ex
rm lib/heads_up_web/controllers/api/goal_comment_controller.ex
rm lib/heads_up_web/controllers/group_controller.ex
```

### API JSON Views (4 files)
```
rm lib/heads_up_web/controllers/api/goal_json.ex
rm lib/heads_up_web/controllers/api/goal_step_json.ex
rm lib/heads_up_web/controllers/api/goal_post_json.ex
rm lib/heads_up_web/controllers/api/goal_comment_json.ex
```

### Components (1 file)
```
rm lib/heads_up_web/components/goal_card.ex
```

### Helpers (1 file — entirely goal-specific)
```
rm lib/heads_up_web/helpers/subscription_helper.ex
```

### Tests (19 files)
```
rm test/heads_up/goal_ownership_test.exs
rm test/heads_up/goal_status_test.exs
rm test/heads_up/goal_deletion_test.exs
rm test/heads_up/goal_failure_test.exs
rm test/heads_up/goal_subscription_test.exs
rm test/heads_up/goals_comment_test.exs
rm test/heads_up/goal_freeze_test.exs
rm test/heads_up_web/live/my_goals_clickable_test.exs
rm test/heads_up_web/live/goal_ownership_liveview_test.exs
rm test/heads_up_web/live/goal_privacy_test.exs
rm test/heads_up_web/live/goal_post_likes_and_image_test.exs
rm test/heads_up_web/live/bug3_failed_goal_post_edit_test.exs
rm test/heads_up_web/live/bug2_failed_goal_restrictions_test.exs
rm test/heads_up_web/live/goal_creation_integration_test.exs
rm test/heads_up_web/live/goal_comment_live_test.exs
rm test/heads_up_web/live/goal_category_live_test.exs
rm test/heads_up_web/controllers/api/goal_controller_test.exs
rm test/heads_up_web/controllers/api/goal_api_test.exs
rm test/heads_up_web/live/admin/groups_live_test.exs
```

### Test Fixtures (2 files)
```
rm test/support/fixtures/goals_fixtures.ex
rm test/support/fixtures/groups_fixtures.ex
```

### Old Migrations (16 files — delete, will be replaced by drop migration)
```
rm priv/repo/migrations/20250524200041_create_groups.exs
rm priv/repo/migrations/20250705080710_create_goals.exs
rm priv/repo/migrations/20250705081401_add_privacy_to_goals.exs
rm priv/repo/migrations/20250705081547_add_image_to_goals.exs
rm priv/repo/migrations/20250705153638_create_goal_likes.exs
rm priv/repo/migrations/20250705153639_create_goal_subscriptions.exs
rm priv/repo/migrations/20250705155909_create_goal_posts.exs
rm priv/repo/migrations/20250705165145_add_big_description_to_goals.exs
rm priv/repo/migrations/20250705165158_create_goal_steps.exs
rm priv/repo/migrations/20250705170839_add_step_id_to_goal_posts.exs
rm priv/repo/migrations/20250706171939_create_goal_post_likes.exs
rm priv/repo/migrations/20250706180218_add_goal_tracking_fields.exs
rm priv/repo/migrations/20250708191847_add_parent_id_to_groups.exs
rm priv/repo/migrations/20260205221726_create_goal_comments.exs
```

---

## Phase 2: Modify Shared Files (~15 files)

### 2.1 `lib/heads_up/users.ex`
- **Line 12**: Remove `field :goal_amount, :integer`
- **Line 30**: Remove `has_many :goals, HeadsUp.Goal, foreign_key: :user_id`
- **Line 60**: Remove `:goal_amount` from changeset cast list
- **Line 108**: Remove `:goal_amount` from registration_changeset cast list

### 2.2 `lib/heads_up/business_rules.ex`
- **Lines 33-34**: Update doc — remove "goals +" from description
- **Lines 38-42**: Simplify `count_active_items/1` to just return `count_active_challenges(user_id)`
- **Lines 72-77**: Delete entire `count_active_goals/1` function

### 2.3 `lib/heads_up/user_activity.ex`
- **Lines 6-11,20**: Remove 7 goal activity types from `@activity_types`: `"goal_created"`, `"goal_completed"`, `"goal_failed"`, `"goal_frozen"`, `"goal_deleted"`, `"goal_updated"`, `"goal_step_completed"`
- **Line 41**: Remove `belongs_to :goal, HeadsUp.Goal`
- **Line 42**: Remove `belongs_to :post, HeadsUp.Goals.GoalPost`
- **Lines 58-59**: Remove `:goal_id`, `:post_id` from changeset cast
- **Lines 67-68**: Remove `foreign_key_constraint(:goal_id)` and `foreign_key_constraint(:post_id)`

### 2.4 `lib/heads_up/activity_service.ex`
- **Lines 49-54,63**: Remove 7 goal XP entries from `@xp_rewards`
- **Line 74**: Remove `goal_id: Keyword.get(opts, :goal_id)`
- **Line 75**: Remove `post_id: Keyword.get(opts, :post_id)`
- **Line 222**: Change preload from `[:user, :goal, :post]` to `[:user]`
- **Lines 234-246**: Remove `total_goals` and `completed_goals` queries from `get_user_stats/1`
- **Lines 270-275**: Remove `completion_rate` calculation (uses total_goals)
- **Lines 288-290**: Remove `:total_goals`, `:completed_goals`, `:completion_rate` from stats map

### 2.5 `lib/heads_up/feed_service.ex`
- **Lines 49-53**: Remove 5 goal activity types from feed query
- **Line 69**: Change preload from `[:user, :goal, :post, :challenge]` to `[:user, :challenge]`
- **Lines 84-91**: Remove entire goal privacy filtering block
- **Line 102**: Update comment "Non-goal/non-challenge" → "Non-challenge"
- **Lines 216-217**: Remove `goal:` and `post:` from `base_data` map in `format_activity_for_feed/1`
- **Line 222**: Remove `goal_title` assignment
- **Lines 227-252**: Remove all goal-related case clauses (goal_created, goal_completed, goal_failed, goal_updated, goal_step_completed, post_created with goal ref, post_liked with goal ref)
- **Lines 325-327**: Remove `"goal_created"`, `"goal_completed"`, `"post_created"` from trending query
- **Line 331**: Remove `a.goal_id` from group_by
- **Line 335**: Change preload from `[:user, :goal, :post, :challenge]` to `[:user, :challenge]`

### 2.6 `lib/heads_up/reports/report.ex`
- **Lines 11-12**: Remove `belongs_to :goal` and `belongs_to :post`
- **Line 25**: Remove `:goal_id, :post_id` from changeset cast
- **Lines 30-31**: Remove `foreign_key_constraint(:goal_id)` and `foreign_key_constraint(:post_id)`
- **Lines 35-36**: Remove unique constraints for goal_id and post_id
- **Lines 41-51**: Update `validate_has_target/1` — remove goal_id/post_id checks, only check reported_user_id and challenge_id

### 2.7 `lib/heads_up/reports.ex`
- **Lines 5-6**: Remove `alias HeadsUp.Goal` and `alias HeadsUp.Goals.GoalPost`
- **Lines 16-32**: Remove entire `report_goal/3` function
- **Lines 34-50**: Remove entire `report_post/3` function
- **Lines 92-95**: Remove `has_reported_goal?/2`
- **Lines 97-100**: Remove `has_reported_post?/2`
- **Lines 112-115**: Remove `goal_report_count/1`
- **Lines 117-120**: Remove `post_report_count/1`
- **Line 132**: Remove `goal_hidden?/1`
- **Line 133**: Remove `post_hidden?/1`
- **Lines 141-147**: Remove `update_goal_report_count/1`
- **Lines 149-155**: Remove `update_post_report_count/1`
- **Lines 204-205**: Remove `:goal` and `:post` cases from `list_reports/1`
- **Line 213**: Change preload to `[:user, :reported_user, :challenge]`
- **Line 218**: Change preload to `[:user, :reported_user, :challenge]`

### 2.8 `lib/heads_up_web/router.ex`
Remove these route blocks:
- **Lines 37-41**: Goal public LiveView routes (GoalLive.New/Show, GoalCategoryLive, AllGoalsLive)
- **Lines 58-59**: Authenticated goal routes (GoalLive.Edit, MyGoalsLive.Index)
- **Line 91**: Admin groups route (Admin.GroupsLive.Index)
- **Lines 119-122**: Group API scope (post "/groups")
- **Lines 186-189**: Public goals API scope
- **Lines 247-285**: Authenticated goals API scope (all goal CRUD + interactions + steps + posts)
- **Lines 287-295**: Post comments API scope
- **Line 284**: Goal report route
- **Line 294**: Post report route
- **Lines 364-366**: Public goal catch-all API route

### 2.9 `lib/heads_up_web/controllers/page_controller.ex`
- **Line 8**: Remove `get_trending_goals()` call
- **Line 11**: Remove `get_popular_groups()` call
- **Lines 20-21**: Remove `trending_goals` and `popular_groups` assigns
- **Lines 27-48**: Delete entire `get_trending_goals/0` function
- **Lines 50-67**: Delete entire `get_popular_groups/0` function
- **Lines 78-79**: Remove `latest_achievement` mapping from user spotlights
- **Lines 83-91**: Delete entire `get_user_latest_achievement/1` function

### 2.10 `lib/heads_up_web/controllers/page_html.ex`
- **Lines 11-13**: Remove `get_default_goal_image/0` function
- **Lines 15-17**: Remove `get_default_group_image/0` function

### 2.11 `lib/heads_up_web/controllers/page_html/home.html.heex`
- **Lines 11,14,18-22**: Remove "Set fewer goals" hero text, "goal-first social network" description, and "Create Your Goal" CTA
- **Lines 37-65**: Remove entire "Goal Categories" section
- **Lines 97-143**: Remove "Top Goal-Setters" section (rename to keep users, just remove goal language)
- **Lines 146-257**: Remove entire "Active Goals" feed section
- **Lines 262-289**: Remove "Popular Groups" right sidebar section
- **Lines 374-376**: Remove "Trending Goals" quick stat

### 2.12 `lib/heads_up_web/components/layouts/app.html.heex`
**Desktop sidebar:**
- **Line 73**: Remove Goals sidebar link (`/all-goals`)
- **Line 75**: Remove Groups sidebar link (`/goals-category`)
- **Line 85**: Remove My Goals sidebar link (`/my-goals`)
- **Line 90**: Remove Create Goal sidebar link (`/goals/new`)
- **Lines 113-117**: Remove admin "Goal Categories" link (`/admin/categories`)
- **Lines 162-177**: Remove "Create a Goal" bottom promo card

**Mobile header:**
- **Lines 205-211**: Remove Create button linking to `/goals/new`

**Mobile drawer:**
- **Lines 317-322**: Remove Goals drawer link
- **Lines 329-334**: Remove Groups drawer link
- **Lines 348-353**: Remove My Goals drawer link
- **Lines 373-378**: Remove Create Goal drawer link
- **Lines 401-406**: Remove admin "Goal Categories" drawer link
- **Lines 462-479**: Remove "Create a Goal" drawer promo card

### 2.13 `lib/heads_up_web/components/home_discovery.ex`
- Remove `goal_card/1` component (lines 116-173)
- Remove `group_card/1` component (lines 175-202)
- Update hero text — remove "Set fewer goals. Finish more." and goal-related CTAs
- Remove "Create your next goal" link and "Explore all goals" link
- Update metric tiles — remove "Trending Goals" and "Popular Groups" tiles

### 2.14 `lib/heads_up_web/components/ui/bottom_nav.ex`
- **Lines 13-18**: Change Explore link from `/all-goals` to `/challenges`
- **Lines 19-25**: Change Create link from `/goals/new` to `/challenges/new`

### 2.15 Seed files
- `priv/repo/seeds.exs` — Remove all goal/group seed data
- `priv/repo/seeds_bulk.exs` — Remove all goal/group seed data

---

## Phase 3: Create Drop Migration

Generate new migration `remove_goals_and_groups` that:
1. Drops indexes on reports table (goal_id, post_id unique indexes)
2. Removes `goal_id`, `post_id` columns from `reports`
3. Removes `goal_id`, `post_id` columns from `user_activities`
4. Removes `goal_amount` column from `users`
5. Drops tables: `goal_comments`, `goal_post_likes`, `goal_posts`, `goal_subscriptions`, `goal_likes`, `goal_steps`, `goals`, `groups`

---

## Phase 4: Database Reset & Verify

1. `mix compile` — verify clean compilation
2. `mix ecto.reset` — drop, create, run remaining migrations + new drop migration
3. Update seeds to only include challenge/user data
4. `mix phx.server` — verify app starts
5. `mix test` — verify remaining tests pass

---

## Verification
- App compiles with `mix compile` (zero errors)
- `mix ecto.reset` succeeds
- `mix phx.server` starts without errors
- Navigate to `/`, `/challenges`, `/people`, `/connections`, `/feed`
- Verify no broken links in sidebar/mobile nav
- `mix test` — all remaining tests pass
- `grep -ri "HeadsUp.Goal" lib/` returns zero matches (excluding challenges)
- `grep -ri "goal" lib/heads_up_web/router.ex` returns zero matches
