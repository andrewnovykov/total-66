# Controller Style Guide

This style guide documents the patterns and conventions used in HeadsUp controller modules.

## Module Structure

### API Controller

```elixir
defmodule HeadsUpWeb.Api.GoalController do
  use HeadsUpWeb, :controller

  import Ecto.Query
  alias HeadsUp.{Goals, Groups, Repo}
  alias HeadsUp.Goal

  action_fallback HeadsUpWeb.FallbackController
```

**Pattern**:
- Namespace API controllers under `HeadsUpWeb.Api`
- Use `action_fallback` for error handling
- Import `Ecto.Query` when needed in controller

### Page Controller (HTML)

```elixir
defmodule HeadsUpWeb.PageController do
  use HeadsUpWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
```

## Action Patterns

### Index Action (List)

```elixir
def index(conn, params) do
  current_user_id = get_current_user_id(conn)

  goals = Goals.list_goals()
  |> Enum.filter(&(&1.privacy == :public))
  |> Repo.preload([:group, :user, :goal_likes, :goal_subscriptions, :goal_steps,
      goal_posts: from(p in HeadsUp.Goals.GoalPost, order_by: [desc: p.inserted_at], preload: [:user])])
  |> Goals.add_social_counts()
  |> apply_filters(params)
  |> paginate(params)

  conn
  |> put_status(:ok)
  |> render(:index, goals: goals, current_user_id: current_user_id)
end
```

**Pattern**: Chain data transformations, pass both data and context to view.

### Show Action (Single Resource)

```elixir
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
            goal = preload_and_enhance(goal)

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

**Pattern**:
- Parse and validate ID
- Check for soft-deleted records
- Check access permissions
- Use explicit status codes

### Create Action

```elixir
def create(conn, %{"goal" => goal_params}) do
  current_user_id = get_current_user_id(conn)

  if current_user_id do
    goal_params = Map.put(goal_params, "user_id", current_user_id)

    case Goals.create_goal(goal_params) do
      {:ok, goal} ->
        goal = preload_and_enhance(goal)

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

**Pattern**: Always check authentication, inject user_id into params.

### Update Action

```elixir
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
                    conn |> put_status(:ok) |> render(:show, goal: updated_goal, current_user_id: current_user_id)

                  {:error, :unauthorized} ->
                    conn |> put_status(:forbidden) |> render(:error, message: "You can only update your own goals")

                  {:error, :frozen} ->
                    conn |> put_status(:forbidden) |> render(:error, message: "Frozen goals cannot be updated")

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

**Pattern**: Handle all error cases from ownership-validated functions.

### Delete Action

```elixir
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

**Pattern**: Use soft delete with ownership check.

### Custom Actions

```elixir
# POST /api/goals/:id/like
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

# POST /api/goals/:id/fail
def fail(conn, %{"id" => id, "reason" => reason}) when is_binary(reason) and reason != "" do
  # Implementation
end

def fail(conn, _params) do
  conn
  |> put_status(:bad_request)
  |> render(:error, message: "Failure reason is required")
end
```

**Pattern**: Use guard clauses for parameter validation.

## HTTP Status Codes

| Status | Use Case |
|--------|----------|
| `:ok` (200) | Successful GET, PUT, PATCH, DELETE |
| `:created` (201) | Successful POST creating resource |
| `:bad_request` (400) | Invalid parameters, malformed request |
| `:unauthorized` (401) | Authentication required |
| `:forbidden` (403) | Authenticated but not authorized |
| `:not_found` (404) | Resource doesn't exist |
| `:unprocessable_entity` (422) | Validation errors |

## Private Helper Functions

### Get Current User

```elixir
defp get_current_user_id(conn) do
  case conn.assigns[:current_user] do
    %{id: user_id} -> user_id
    _ -> nil
  end
end
```

### Access Control

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

### Sorting

```elixir
defp sort_goals(goals, "created_desc"), do: Enum.sort_by(goals, &(&1.inserted_at), {:desc, DateTime})
defp sort_goals(goals, "created_asc"), do: Enum.sort_by(goals, &(&1.inserted_at), {:asc, DateTime})
defp sort_goals(goals, "updated_desc"), do: Enum.sort_by(goals, &(&1.updated_at), {:desc, DateTime})
defp sort_goals(goals, "progress_desc"), do: Enum.sort_by(goals, &(&1.progress), :desc)
defp sort_goals(goals, "progress_asc"), do: Enum.sort_by(goals, &(&1.progress), :asc)
defp sort_goals(goals, "title_asc"), do: Enum.sort_by(goals, &(String.downcase(&1.title)), :asc)
defp sort_goals(goals, _), do: goals
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

## Session Controller Pattern

```elixir
defmodule HeadsUpWeb.UserSessionController do
  use HeadsUpWeb, :controller

  alias HeadsUp.Auth
  alias HeadsUpWeb.UserAuth

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Auth.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> UserAuth.log_in_user(user, user_params)
    else
      conn
      |> put_flash(:error, "Invalid email or password")
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
```

## Fallback Controller

```elixir
defmodule HeadsUpWeb.FallbackController do
  use HeadsUpWeb, :controller

  # Handle changeset errors
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(HeadsUpWeb.ErrorJSON)
    |> render(:error, changeset: changeset)
  end

  # Handle not found
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(HeadsUpWeb.ErrorJSON)
    |> render(:not_found)
  end

  # Handle unauthorized
  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:forbidden)
    |> put_view(HeadsUpWeb.ErrorJSON)
    |> render(:forbidden)
  end
end
```
