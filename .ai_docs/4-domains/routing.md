# Routing Patterns - Domain Documentation

## Overview

HeadsUp uses Phoenix Router for routing configuration with separate pipelines for browser and API requests. LiveViews are organized in `live_session` blocks with shared `on_mount` hooks for authentication.

## Router File

| File | Purpose |
|------|---------|
| `/lib/heads_up_web/router.ex` | Main router configuration |

## Pipeline Configuration

### Browser Pipeline

```elixir
# File: /lib/heads_up_web/router.ex
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :fetch_live_flash
  plug :put_root_layout, html: {HeadsUpWeb.Layouts, :root}
  plug :protect_from_forgery
  plug :put_secure_browser_headers
  plug :fetch_current_user  # Auth plug
end
```

### API Pipeline

```elixir
# File: /lib/heads_up_web/router.ex
pipeline :api do
  plug :accepts, ["json"]
  plug :fetch_session
  plug :fetch_current_user  # Auth plug for optional auth
end

pipeline :api_auth do
  plug :accepts, ["json"]
  plug :fetch_session
  plug :require_authenticated_user_api  # Require auth
end
```

## Live Session Pattern

### Public Pages (Optional Auth)

```elixir
# File: /lib/heads_up_web/router.ex
scope "/", HeadsUpWeb do
  pipe_through :browser

  get "/", PageController, :home

  # Public pages - accessible to everyone (guests and authenticated users)
  live_session :public,
    on_mount: [{HeadsUpWeb.UserAuth, :mount_current_user}] do
    live "/goals", GoalLive.Index
    live "/goals/new", GoalLive.New
    live "/goals/:id", GoalLive.Show
    live "/goals-category", GoalCategoryLive.Index
    live "/goals-category/:id", GoalCategoryLive.Show
    live "/all-goals", AllGoalsLive.Index
    live "/challenges", ChallengeLive.Index
    live "/challenges/:id", ChallengeLive.Show
    live "/people", UsersLive.Index
    live "/people/:username", UsersLive.Show
  end
end
```

### Authenticated Pages

```elixir
# File: /lib/heads_up_web/router.ex
scope "/", HeadsUpWeb do
  pipe_through [:browser, :require_authenticated_user]

  # Authenticated-only pages
  live_session :authenticated,
    on_mount: [{HeadsUpWeb.UserAuth, :ensure_authenticated}] do
    live "/goals/:id/edit", GoalLive.Edit
    live "/my-goals", MyGoalsLive.Index
    live "/challenges/new", ChallengeLive.New
    live "/challenges/:id/edit", ChallengeLive.Edit
    live "/my-challenges", ChallengeLive.MyChallenges
    live "/connections", ConnectionsLive.Index
    live "/feed", FeedLive.Index
  end
end
```

### Admin Pages

```elixir
# File: /lib/heads_up_web/router.ex
scope "/admin", HeadsUpWeb do
  pipe_through [:browser, :require_authenticated_user]

  # Admin-only pages
  live_session :admin,
    on_mount: [
      {HeadsUpWeb.UserAuth, :ensure_authenticated},
      {HeadsUpWeb.AdminAuth, :ensure_admin}
    ] do
    live "/categories", Admin.GroupsLive.Index
    live "/challenge-categories", Admin.ChallengeCategoriesLive.Index
  end
end
```

### Auth Pages (Redirect if Authenticated)

```elixir
# File: /lib/heads_up_web/router.ex
scope "/", HeadsUpWeb do
  pipe_through [:browser, :redirect_if_user_is_authenticated]

  live_session :redirect_if_user_is_authenticated,
    on_mount: [{HeadsUpWeb.UserAuth, :redirect_if_user_is_authenticated}] do
    live "/users/register", UserRegistrationLive, :new
    live "/users/log_in", UserLoginLive, :new
    live "/users/reset_password", UserForgotPasswordLive, :new
    live "/users/reset_password/:token", UserResetPasswordLive, :edit
  end

  post "/users/log_in", UserSessionController, :create
end
```

### User Settings (Require Auth)

```elixir
# File: /lib/heads_up_web/router.ex
scope "/", HeadsUpWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :require_authenticated_user,
    on_mount: [{HeadsUpWeb.UserAuth, :ensure_authenticated}] do
    live "/users/settings", UserSettingsLive, :edit
    live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
  end
end
```

## API Route Organization

### Public API Routes

```elixir
# File: /lib/heads_up_web/router.ex
scope "/api", HeadsUpWeb.Api, as: :api do
  pipe_through :api

  # Public category endpoints
  scope "/categories" do
    get "/", CategoryController, :index
    get "/:id", CategoryController, :show
    get "/:id/subcategories", CategoryController, :subcategories
  end

  # Public Goals API endpoints
  scope "/goals" do
    get "/", GoalController, :index
    get "/category/:category_id", GoalController, :by_category
  end
end

# Note: Public goal show must be last due to :id catch-all
scope "/api", HeadsUpWeb.Api, as: :api do
  pipe_through :api

  scope "/goals" do
    get "/:id", GoalController, :show
  end
end
```

### Authenticated API Routes

```elixir
# File: /lib/heads_up_web/router.ex
scope "/api", HeadsUpWeb.Api, as: :api do
  pipe_through [:api, :require_authenticated_user_api]

  # Authenticated Goals API endpoints
  scope "/goals" do
    get "/my", GoalController, :my_goals
    post "/", GoalController, :create
    put "/:id", GoalController, :update
    patch "/:id", GoalController, :update
    delete "/:id", GoalController, :delete

    # Goal interaction endpoints
    post "/:id/like", GoalController, :like
    delete "/:id/like", GoalController, :unlike
    post "/:id/subscribe", GoalController, :subscribe
    delete "/:id/subscribe", GoalController, :unsubscribe

    # Goal management endpoints
    post "/:id/restore", GoalController, :restore
    post "/:id/fail", GoalController, :fail
    post "/:id/freeze", GoalController, :freeze
    post "/:id/unfreeze", GoalController, :unfreeze
    get "/deleted", GoalController, :deleted_goals
  end

  # User relationship endpoints
  scope "/users" do
    post "/:id/follow", UserController, :follow
    delete "/:id/follow", UserController, :unfollow
    post "/:id/friend-request", UserController, :send_friend_request
  end

  # Friend requests management
  scope "/friend-requests" do
    get "/", UserController, :list_friend_requests
    post "/:id/accept", UserController, :accept_friend_request
    post "/:id/decline", UserController, :decline_friend_request
    delete "/:id", UserController, :cancel_friend_request
  end

  # Friends management
  scope "/friends" do
    get "/", UserController, :list_friends
    delete "/:id", UserController, :remove_friend
  end

  # Admin-only category management
  scope "/admin/categories" do
    post "/", CategoryController, :create
    put "/:id", CategoryController, :update
    patch "/:id", CategoryController, :update
    delete "/:id", CategoryController, :delete
  end

  # Activity and feed endpoints
  scope "/activities" do
    get "/:user_id", ActivityController, :user_activities
  end

  scope "/feed" do
    get "/", ActivityController, :user_feed
  end

  scope "/chart" do
    get "/:user_id", ActivityController, :chart_data
  end

  scope "/users/:user_id" do
    get "/stats", ActivityController, :user_stats
  end
end
```

## Development Routes

```elixir
# File: /lib/heads_up_web/router.ex
if Application.compile_env(:heads_up, :dev_routes) do
  import Phoenix.LiveDashboard.Router

  scope "/dev" do
    pipe_through :browser

    live_dashboard "/dashboard", metrics: HeadsUpWeb.Telemetry
    forward "/mailbox", Plug.Swoosh.MailboxPreview
  end
end
```

## Verified Routes

Using the `~p` sigil for type-safe route generation:

```elixir
# In templates
<.link navigate={~p"/goals/#{goal.id}"}>View Goal</.link>
<.link navigate={~p"/people/#{user.user_name}"}>View Profile</.link>

# In controllers/LiveViews
push_navigate(socket, to: ~p"/goals/#{goal_id}")
redirect(to: ~p"/users/log_in")
```

## Route Helpers

### Live Routes

```elixir
# LiveView routes with actions
live "/users/settings", UserSettingsLive, :edit
live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

# LiveView routes without actions
live "/goals", GoalLive.Index
live "/goals/:id", GoalLive.Show
```

### Controller Routes

```elixir
# Standard controller routes
get "/", PageController, :home
post "/users/log_in", UserSessionController, :create
delete "/users/log_out", UserSessionController, :delete
```

### Scoped Routes

```elixir
# Scope for logical grouping
scope "/admin", HeadsUpWeb do
  # Admin routes
end

scope "/api", HeadsUpWeb.Api, as: :api do
  # API routes
end
```

## On Mount Hooks

### Available Hooks

| Hook | Purpose | Effect |
|------|---------|--------|
| `:mount_current_user` | Load current user without requiring auth | Assigns `current_user` (may be nil) |
| `:ensure_authenticated` | Require authentication | Redirects to login if not authenticated |
| `:redirect_if_user_is_authenticated` | Redirect if already logged in | Redirects to home if authenticated |
| `:ensure_admin` | Require admin role | Requires admin in addition to auth |

### Hook Usage

```elixir
# Single hook
live_session :public,
  on_mount: [{HeadsUpWeb.UserAuth, :mount_current_user}] do
  # ...
end

# Multiple hooks (evaluated in order)
live_session :admin,
  on_mount: [
    {HeadsUpWeb.UserAuth, :ensure_authenticated},
    {HeadsUpWeb.AdminAuth, :ensure_admin}
  ] do
  # ...
end
```

## Route Summary

| Path Pattern | Auth Level | Handler |
|--------------|------------|---------|
| `/` | Public | PageController |
| `/goals` | Public (optional auth) | GoalLive.Index |
| `/goals/:id` | Public (optional auth) | GoalLive.Show |
| `/goals/:id/edit` | Authenticated | GoalLive.Edit |
| `/my-goals` | Authenticated | MyGoalsLive.Index |
| `/feed` | Authenticated | FeedLive.Index |
| `/connections` | Authenticated | ConnectionsLive.Index |
| `/people` | Public (optional auth) | UsersLive.Index |
| `/people/:username` | Public (optional auth) | UsersLive.Show |
| `/admin/categories` | Admin | Admin.GroupsLive.Index |
| `/users/register` | Guest only | UserRegistrationLive |
| `/users/log_in` | Guest only | UserLoginLive |
| `/users/settings` | Authenticated | UserSettingsLive |
| `/api/goals` | Public | GoalController |
| `/api/goals/my` | Authenticated | GoalController |
| `/api/users/:id/follow` | Authenticated | UserController |

## Architectural Constraints

1. **Live Session**: Group LiveViews in `live_session` with shared `on_mount` hooks
2. **Pipeline Separation**: Separate browser and API pipelines
3. **Scoped Routes**: Use scope for logical grouping (`/admin`, `/api`)
4. **Auth in Pipeline**: Authentication plugs in pipeline, not individual routes
5. **Verified Routes**: Use `~p` sigil for type-safe route generation
6. **Admin Protection**: Admin routes require both authentication and admin role check
7. **API Route Order**: Place specific routes before catch-all `:id` routes
