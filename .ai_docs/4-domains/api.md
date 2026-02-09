# API Controller Patterns - Domain Documentation

## Overview

HeadsUp provides a JSON API for goals, users, categories, and activities. API controllers follow RESTful conventions, use action_fallback for error handling, and separate JSON view modules for response formatting.

## API Files

| Controller | File Path | Purpose |
|------------|-----------|---------|
| `HeadsUpWeb.Api.GoalController` | `/lib/heads_up_web/controllers/api/goal_controller.ex` | Goal CRUD and interactions |
| `HeadsUpWeb.Api.UserController` | `/lib/heads_up_web/controllers/api/user_controller.ex` | User follows and friendships |
| `HeadsUpWeb.Api.CategoryController` | `/lib/heads_up_web/controllers/api/category_controller.ex` | Category management |
| `HeadsUpWeb.Api.ActivityController` | `/lib/heads_up_web/controllers/api/activity_controller.ex` | Activity feed and stats |
| `HeadsUpWeb.FallbackController` | `/lib/heads_up_web/controllers/fallback_controller.ex` | Error handling |

| JSON View | File Path | Purpose |
|-----------|-----------|---------|
| `HeadsUpWeb.Api.GoalJSON` | `/lib/heads_up_web/controllers/api/goal_json.ex` | Goal response formatting |
| `HeadsUpWeb.Api.UserJSON` | `/lib/heads_up_web/controllers/api/user_json.ex` | User response formatting |
| `HeadsUpWeb.Api.CategoryJSON` | `/lib/heads_up_web/controllers/api/category_json.ex` | Category response formatting |
| `HeadsUpWeb.Api.ActivityJSON` | `/lib/heads_up_web/controllers/api/activity_json.ex` | Activity response formatting |

## Controller Structure

### Standard API Controller Pattern

```elixir
# File: /lib/heads_up_web/controllers/api/goal_controller.ex
defmodule HeadsUpWeb.Api.GoalController do
  use HeadsUpWeb, :controller

  import Ecto.Query
  alias HeadsUp.{Goals, Groups, Repo}
  alias HeadsUp.Goal

  action_fallback HeadsUpWeb.FallbackController

  # Actions...
end
```

## Action Fallback Pattern

```elixir
# File: /lib/heads_up_web/controllers/fallback_controller.ex
defmodule HeadsUpWeb.FallbackController do
  use HeadsUpWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: HeadsUpWeb.Api.GoalJSON)
    |> render(:error, message: "Resource not found")
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: HeadsUpWeb.Api.GoalJSON)
    |> render(:changeset_error, changeset: changeset)
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(json: HeadsUpWeb.Api.GoalJSON)
    |> render(:error, message: "Unauthorized")
  end

  def call(conn, {:error, message}) when is_binary(message) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(json: HeadsUpWeb.Api.GoalJSON)
    |> render(:error, message: message)
  end

  def call(conn, _error) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(json: HeadsUpWeb.Api.GoalJSON)
    |> render(:error, message: "Internal server error")
  end
end
```

## RESTful Actions

### Index Action

```elixir
# GET /api/goals - Get all public goals
def index(conn, params) do
  current_user_id = get_current_user_id(conn)

  goals = Goals.list_goals()
  |> Enum.filter(&(&1.privacy == :public))
  |> Repo.preload([...])
  |> Goals.add_social_counts()
  |> apply_filters(params)
  |> paginate(params)

  conn
  |> put_status(:ok)
  |> render(:index, goals: goals, current_user_id: current_user_id)
end
```

### Show Action

```elixir
# GET /api/goals/:id - Get specific goal by ID
def show(conn, %{"id" => id}) do
  current_user_id = get_current_user_id(conn)

  case Integer.parse(id) do
    {goal_id, _} ->
      case Goals.get_goal(goal_id) do
        nil ->
          conn
          |> put_status(:not_found)
          |> render(:error, message: "Goal not found")

        goal ->
          if goal.deleted_at do
            conn
            |> put_status(:not_found)
            |> render(:error, message: "Goal not found")
          else
            goal = Repo.preload(goal, [...])

            if can_view_goal?(goal, current_user_id) do
              conn
              |> put_status(:ok)
              |> render(:show, goal: goal, current_user_id: current_user_id)
            else
              conn
              |> put_status(:forbidden)
              |> render(:error, message: "Access denied")
            end
          end
      end

    :error ->
      conn
      |> put_status(:bad_request)
      |> render(:error, message: "Invalid goal ID")
  end
end
```

### Create Action

```elixir
# POST /api/goals - Create new goal
def create(conn, %{"goal" => goal_params}) do
  current_user_id = get_current_user_id(conn)

  if current_user_id do
    goal_params = Map.put(goal_params, "user_id", current_user_id)

    case Goals.create_goal(goal_params) do
      {:ok, goal} ->
        goal = Repo.preload(goal, [...])
        goal = [goal] |> Goals.add_social_counts() |> List.first()

        conn
        |> put_status(:created)
        |> render(:show, goal: goal, current_user_id: current_user_id)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:changeset_error, changeset: changeset)
    end
  else
    conn
    |> put_status(:unauthorized)
    |> render(:error, message: "Authentication required")
  end
end
```

### Update Action

```elixir
# PUT /api/goals/:id - Update goal
def update(conn, %{"id" => id, "goal" => goal_params}) do
  current_user_id = get_current_user_id(conn)

  if current_user_id do
    case Integer.parse(id) do
      {goal_id, _} ->
        case Goals.get_goal(goal_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> render(:error, message: "Goal not found")

          goal ->
            cond do
              goal.deleted_at ->
                conn |> put_status(:not_found) |> render(:error, message: "Goal not found")

              goal.status == :failed ->
                conn |> put_status(:forbidden) |> render(:error, message: "Failed goals can only be deleted")

              true ->
                case Goals.update_goal_with_ownership(goal, goal_params, current_user_id) do
                  {:ok, updated_goal} ->
                    updated_goal = Repo.preload(updated_goal, [...])
                    conn |> put_status(:ok) |> render(:show, goal: updated_goal, current_user_id: current_user_id)

                  {:error, :unauthorized} ->
                    conn |> put_status(:forbidden) |> render(:error, message: "You can only update your own goals")

                  {:error, :frozen} ->
                    conn |> put_status(:forbidden) |> render(:error, message: "Frozen goals cannot be updated.")

                  {:error, changeset} ->
                    conn |> put_status(:unprocessable_entity) |> render(:changeset_error, changeset: changeset)
                end
            end
        end

      :error ->
        conn |> put_status(:bad_request) |> render(:error, message: "Invalid goal ID")
    end
  else
    conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
  end
end
```

### Delete Action

```elixir
# DELETE /api/goals/:id - Delete goal
def delete(conn, %{"id" => id}) do
  current_user_id = get_current_user_id(conn)

  if current_user_id do
    case Integer.parse(id) do
      {goal_id, _} ->
        case Goals.get_goal(goal_id) do
          nil ->
            conn |> put_status(:not_found) |> render(:error, message: "Goal not found")

          goal ->
            case Goals.soft_delete_goal_with_ownership(goal, current_user_id) do
              {:ok, _deleted_goal} ->
                conn |> put_status(:ok) |> render(:delete, message: "Goal deleted successfully")

              {:error, :unauthorized} ->
                conn |> put_status(:forbidden) |> render(:error, message: "You can only delete your own goals")

              {:error, _changeset} ->
                conn |> put_status(:unprocessable_entity) |> render(:error, message: "Failed to delete goal")
            end
        end

      :error ->
        conn |> put_status(:bad_request) |> render(:error, message: "Invalid goal ID")
    end
  else
    conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
  end
end
```

## Custom Actions

### Like/Unlike

```elixir
# POST /api/goals/:id/like - Like a goal
def like(conn, %{"id" => id}) do
  current_user_id = get_current_user_id(conn)

  if current_user_id do
    case Integer.parse(id) do
      {goal_id, _} ->
        case Goals.like_goal(goal_id, current_user_id) do
          {:ok, _} ->
            conn |> put_status(:ok) |> render(:action_success, message: "Goal liked successfully")

          {:error, :cannot_like_own_goal} ->
            conn |> put_status(:forbidden) |> render(:error, message: "You cannot like your own goal")

          {:error, _} ->
            conn |> put_status(:unprocessable_entity) |> render(:error, message: "Failed to like goal")
        end

      :error ->
        conn |> put_status(:bad_request) |> render(:error, message: "Invalid goal ID")
    end
  else
    conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
  end
end

# DELETE /api/goals/:id/like - Unlike a goal
def unlike(conn, %{"id" => id}) do
  current_user_id = get_current_user_id(conn)

  if current_user_id do
    case Integer.parse(id) do
      {goal_id, _} ->
        case Goals.unlike_goal(goal_id, current_user_id) do
          {:ok, _} ->
            conn |> put_status(:ok) |> render(:action_success, message: "Goal unliked successfully")

          {:error, _} ->
            conn |> put_status(:unprocessable_entity) |> render(:error, message: "Failed to unlike goal")
        end

      :error ->
        conn |> put_status(:bad_request) |> render(:error, message: "Invalid goal ID")
    end
  else
    conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
  end
end
```

### Freeze/Unfreeze

```elixir
# POST /api/goals/:id/freeze - Freeze a goal
def freeze(conn, %{"id" => id}) do
  current_user_id = get_current_user_id(conn)

  if current_user_id do
    case Integer.parse(id) do
      {goal_id, _} ->
        case Goals.get_goal(goal_id) do
          nil ->
            conn |> put_status(:not_found) |> render(:error, message: "Goal not found")

          goal ->
            if goal.deleted_at do
              conn |> put_status(:not_found) |> render(:error, message: "Goal not found")
            else
              case Goals.freeze_goal_with_ownership(goal, current_user_id) do
                {:ok, frozen_goal} ->
                  frozen_goal = Repo.preload(frozen_goal, [...])
                  conn |> put_status(:ok) |> render(:show, goal: frozen_goal, current_user_id: current_user_id)

                {:error, :unauthorized} ->
                  conn |> put_status(:forbidden) |> render(:error, message: "You can only freeze your own goals")

                {:error, :failed} ->
                  conn |> put_status(:forbidden) |> render(:error, message: "Failed goals cannot be frozen")

                {:error, _changeset} ->
                  conn |> put_status(:unprocessable_entity) |> render(:error, message: "Failed to freeze goal")
              end
            end
        end

      :error ->
        conn |> put_status(:bad_request) |> render(:error, message: "Invalid goal ID")
    end
  else
    conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
  end
end
```

### Fail with Reason

```elixir
# POST /api/goals/:id/fail - Mark goal as failed with reason
def fail(conn, %{"id" => id, "reason" => reason}) when is_binary(reason) and reason != "" do
  current_user_id = get_current_user_id(conn)

  if current_user_id do
    case Integer.parse(id) do
      {goal_id, _} ->
        case Goals.get_goal(goal_id) do
          nil ->
            conn |> put_status(:not_found) |> render(:error, message: "Goal not found")

          goal ->
            if goal.deleted_at do
              conn |> put_status(:not_found) |> render(:error, message: "Goal not found")
            else
              case Goals.fail_goal_with_ownership(goal, reason, current_user_id) do
                {:ok, failed_goal} ->
                  failed_goal = Repo.preload(failed_goal, [...])
                  conn |> put_status(:ok) |> render(:show, goal: failed_goal, current_user_id: current_user_id)

                {:error, :unauthorized} ->
                  conn |> put_status(:forbidden) |> render(:error, message: "You can only fail your own goals")

                {:error, _changeset} ->
                  conn |> put_status(:unprocessable_entity) |> render(:error, message: "Failed to mark goal as failed")
              end
            end
        end

      :error ->
        conn |> put_status(:bad_request) |> render(:error, message: "Invalid goal ID")
    end
  else
    conn |> put_status(:unauthorized) |> render(:error, message: "Authentication required")
  end
end

def fail(conn, _params) do
  conn |> put_status(:bad_request) |> render(:error, message: "Failure reason is required")
end
```

## Helper Functions

### Get Current User

```elixir
defp get_current_user_id(conn) do
  case conn.assigns[:current_user] do
    %{id: user_id} -> user_id
    _ -> nil
  end
end
```

### Privacy Check

```elixir
defp can_view_goal?(goal, current_user_id) do
  case goal.privacy do
    :public -> true
    :private -> current_user_id && current_user_id == goal.user_id
    :friends -> current_user_id && (current_user_id == goal.user_id || are_friends?(current_user_id, goal.user_id))
    _ -> false
  end
end

defp are_friends?(user1_id, user2_id) do
  HeadsUp.Accounts.are_friends?(user1_id, user2_id)
end
```

### Filtering

```elixir
defp apply_filters(goals, params) do
  goals
  |> filter_by_status(params["status"])
  |> filter_by_search(params["search"])
  |> sort_goals(params["sort"])
end

defp filter_by_status(goals, nil), do: goals
defp filter_by_status(goals, status) when status in ["active", "completed", "paused", "cancelled"] do
  status_atom = String.to_atom(status)
  Enum.filter(goals, &(&1.status == status_atom))
end
defp filter_by_status(goals, _), do: goals

defp filter_by_search(goals, nil), do: goals
defp filter_by_search(goals, ""), do: goals
defp filter_by_search(goals, search_term) do
  search_term = String.downcase(search_term)

  Enum.filter(goals, fn goal ->
    title_match = String.contains?(String.downcase(goal.title), search_term)
    desc_match = goal.description && String.contains?(String.downcase(goal.description), search_term)
    category_match = goal.group && String.contains?(String.downcase(goal.group.name), search_term)
    user_match = goal.user && String.contains?(String.downcase(goal.user.name), search_term)

    title_match || desc_match || category_match || user_match
  end)
end
```

### Pagination

```elixir
defp paginate(goals, params) do
  page = case params["page"] do
    nil -> 1
    page_str ->
      case Integer.parse(page_str) do
        {page, _} when page > 0 -> page
        _ -> 1
      end
  end

  per_page = case params["per_page"] do
    nil -> 20
    per_page_str ->
      case Integer.parse(per_page_str) do
        {per_page, _} when per_page > 0 and per_page <= 100 -> per_page
        _ -> 20
      end
  end

  offset = (page - 1) * per_page

  goals
  |> Enum.drop(offset)
  |> Enum.take(per_page)
end
```

## Router Configuration

```elixir
# File: /lib/heads_up_web/router.ex

# Public API Routes
scope "/api", HeadsUpWeb.Api, as: :api do
  pipe_through :api

  scope "/goals" do
    get "/", GoalController, :index
    get "/category/:category_id", GoalController, :by_category
    get "/:id", GoalController, :show
  end

  scope "/categories" do
    get "/", CategoryController, :index
    get "/:id", CategoryController, :show
  end
end

# Authenticated API Routes
scope "/api", HeadsUpWeb.Api, as: :api do
  pipe_through [:api, :require_authenticated_user_api]

  scope "/goals" do
    get "/my", GoalController, :my_goals
    post "/", GoalController, :create
    put "/:id", GoalController, :update
    patch "/:id", GoalController, :update
    delete "/:id", GoalController, :delete

    post "/:id/like", GoalController, :like
    delete "/:id/like", GoalController, :unlike
    post "/:id/subscribe", GoalController, :subscribe
    delete "/:id/subscribe", GoalController, :unsubscribe

    post "/:id/restore", GoalController, :restore
    post "/:id/fail", GoalController, :fail
    post "/:id/freeze", GoalController, :freeze
    post "/:id/unfreeze", GoalController, :unfreeze
    get "/deleted", GoalController, :deleted_goals
  end

  scope "/users" do
    post "/:id/follow", UserController, :follow
    delete "/:id/follow", UserController, :unfollow
    post "/:id/friend-request", UserController, :send_friend_request
  end
end
```

## Architectural Constraints

1. **RESTful Actions**: Follow REST conventions (index, show, create, update, delete)
2. **JSON Responses**: Return consistent JSON structure with success/error keys
3. **Action Fallback**: Use FallbackController for centralized error handling
4. **JSON View Modules**: Separate `*_json.ex` modules for response formatting
5. **Scoped Routing**: API routes under `/api` scope with proper pipelines
6. **Auth Pipeline**: Use `require_authenticated_user_api` for protected endpoints
