# Router Style Guide

This style guide documents the patterns and conventions used in the HeadsUp router.

## Module Structure

```elixir
defmodule HeadsUpWeb.Router do
  use HeadsUpWeb, :router

  import HeadsUpWeb.UserAuth

  # Pipelines
  # Scopes
  # Routes
end
```

**Pattern**: Import auth module at module level for plug access.

## Pipeline Definitions

### Browser Pipeline

```elixir
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :fetch_live_flash
  plug :put_root_layout, html: {HeadsUpWeb.Layouts, :root}
  plug :protect_from_forgery
  plug :put_secure_browser_headers
  plug :fetch_current_user
end
```

**Pattern**: Standard browser pipeline with custom `fetch_current_user` plug.

### API Pipeline

```elixir
pipeline :api do
  plug :accepts, ["json"]
  plug :fetch_session
  plug :fetch_current_user
end
```

**Pattern**: API pipeline fetches session for optional authentication.

### Authenticated API Pipeline

```elixir
pipeline :api_auth do
  plug :accepts, ["json"]
  plug :fetch_session
  plug :require_authenticated_user_api
end
```

**Pattern**: Separate pipeline for required authentication.

## Scope Organization

### Public Routes

```elixir
scope "/", HeadsUpWeb do
  pipe_through :browser

  get "/", PageController, :home

  # Public pages - accessible to everyone
  live_session :public,
    on_mount: [{HeadsUpWeb.UserAuth, :mount_current_user}] do
    live "/goals", GoalLive.Index
    live "/goals/new", GoalLive.New
    live "/goals/:id", GoalLive.Show
    live "/goals-category", GoalCategoryLive.Index
    live "/goals-category/:id", GoalCategoryLive.Show
    live "/all-goals", AllGoalsLive.Index
    live "/people", UsersLive.Index
    live "/people/:username", UsersLive.Show
  end
end
```

**Pattern**:
- Use `:mount_current_user` for public routes (user may or may not be logged in)
- Name live sessions descriptively (`:public`, `:authenticated`, `:admin`)

### Authenticated Routes

```elixir
scope "/", HeadsUpWeb do
  pipe_through [:browser, :require_authenticated_user]

  # Authenticated-only pages
  live_session :authenticated,
    on_mount: [{HeadsUpWeb.UserAuth, :ensure_authenticated}] do
    live "/goals/:id/edit", GoalLive.Edit
    live "/my-goals", MyGoalsLive.Index
    live "/connections", ConnectionsLive.Index
    live "/feed", FeedLive.Index
  end
end
```

**Pattern**: Double protection with pipeline plug AND LiveView on_mount.

### Admin Routes

```elixir
scope "/admin", HeadsUpWeb do
  pipe_through [:browser, :require_authenticated_user]

  # Admin-only pages
  live_session :admin,
    on_mount: [
      {HeadsUpWeb.UserAuth, :ensure_authenticated},
      {HeadsUpWeb.AdminAuth, :ensure_admin}
    ] do
    live "/categories", Admin.GroupsLive.Index
  end
end
```

**Pattern**:
- Separate scope with `/admin` prefix
- Stack multiple on_mount callbacks for layered authorization
- Authentication checked before admin check

## API Route Organization

### Public API Routes

```elixir
scope "/api", HeadsUpWeb.Api, as: :api do
  pipe_through :api

  # Public category endpoints
  scope "/categories" do
    get "/", CategoryController, :index
    get "/:id", CategoryController, :show
    get "/:id/subcategories", CategoryController, :subcategories
  end
end
```

**Pattern**:
- Namespace under `HeadsUpWeb.Api`
- Use `as: :api` for route helper naming
- Nested scopes for resource grouping

### Authenticated API Routes

```elixir
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
end
```

**Pattern**:
- Custom actions use POST for mutations
- Delete actions use DELETE HTTP method
- Both `put` and `patch` map to `:update` action

### User Relationship Endpoints

```elixir
scope "/users" do
  post "/:id/follow", UserController, :follow
  delete "/:id/follow", UserController, :unfollow
  post "/:id/friend-request", UserController, :send_friend_request
end

scope "/friend-requests" do
  get "/", UserController, :list_friend_requests
  post "/:id/accept", UserController, :accept_friend_request
  post "/:id/decline", UserController, :decline_friend_request
  delete "/:id", UserController, :cancel_friend_request
end

scope "/friends" do
  get "/", UserController, :list_friends
  delete "/:id", UserController, :remove_friend
end
```

**Pattern**: Separate scopes for related resource types.

### Catch-All Routes Last

```elixir
# Public API Routes (must be last due to catch-all :id route)
scope "/api", HeadsUpWeb.Api, as: :api do
  pipe_through :api

  scope "/goals" do
    get "/:id", GoalController, :show
  end
end
```

**Pattern**: Place routes with `:id` parameters last to prevent matching before specific routes.

## Authentication Routes

### Guest-Only Routes

```elixir
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

**Pattern**:
- Redirect authenticated users away from auth pages
- Login POST is outside live_session (handled by controller)

### User Settings Routes

```elixir
scope "/", HeadsUpWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :require_authenticated_user,
    on_mount: [{HeadsUpWeb.UserAuth, :ensure_authenticated}] do
    live "/users/settings", UserSettingsLive, :edit
    live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
  end
end
```

### Mixed Access Routes

```elixir
scope "/", HeadsUpWeb do
  pipe_through [:browser]

  delete "/users/log_out", UserSessionController, :delete

  live_session :current_user,
    on_mount: [{HeadsUpWeb.UserAuth, :mount_current_user}] do
    live "/users/confirm/:token", UserConfirmationLive, :edit
    live "/users/confirm", UserConfirmationInstructionsLive, :new
  end
end
```

**Pattern**: Logout accessible to all, confirmation pages mount current user if present.

## Development Routes

```elixir
if Application.compile_env(:heads_up, :dev_routes) do
  import Phoenix.LiveDashboard.Router

  scope "/dev" do
    pipe_through :browser

    live_dashboard "/dashboard", metrics: HeadsUpWeb.Telemetry
    forward "/mailbox", Plug.Swoosh.MailboxPreview
  end
end
```

**Pattern**:
- Conditionally compile dev routes based on config
- Use `forward` for external plugs like mailbox preview

## Route Commenting

```elixir
scope "/goals" do
  # GET /api/goals - List all public goals
  get "/", GoalController, :index
  # GET /api/goals/category/:id - Goals by category
  get "/category/:category_id", GoalController, :by_category
end
```

**Pattern**: Comment routes with full path for API documentation.

## Naming Conventions

| Route Type | Path Convention | Example |
|------------|-----------------|---------|
| List | `GET /resources` | `GET /goals` |
| Show | `GET /resources/:id` | `GET /goals/:id` |
| Create | `POST /resources` | `POST /goals` |
| Update | `PUT/PATCH /resources/:id` | `PUT /goals/:id` |
| Delete | `DELETE /resources/:id` | `DELETE /goals/:id` |
| Custom Action | `POST /resources/:id/action` | `POST /goals/:id/like` |
| Collection Action | `GET /resources/action` | `GET /goals/deleted` |

## LiveView Actions

```elixir
live "/users/settings", UserSettingsLive, :edit
live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
```

**Pattern**: Third argument specifies LiveView action for `handle_params` dispatch.

## Scope Module Aliasing

```elixir
# Full module path
scope "/api", HeadsUpWeb.Api, as: :api do

# Nested scope (inherits parent alias)
scope "/goals" do
  # Routes use HeadsUpWeb.Api.GoalController
  get "/", GoalController, :index
end
```

**Pattern**: Parent scope module alias applies to all nested routes.
