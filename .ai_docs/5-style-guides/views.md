# Views (JSON Renderers) Style Guide

This style guide documents the patterns and conventions used in HeadsUp view modules (JSON renderers).

## Module Structure

### API JSON View

```elixir
defmodule HeadsUpWeb.Api.GoalJSON do
  @moduledoc """
  JSON views for Goal API endpoints
  """

  alias HeadsUp.Goal

  # Public render functions
  def index(%{goals: goals, current_user_id: current_user_id}) do
    # ...
  end

  # Private helper functions
  defp goal_data(goal, current_user_id) do
    # ...
  end
end
```

**Pattern**:
- Namespace under `HeadsUpWeb.Api`
- Suffix with `JSON` for API views
- Add moduledoc describing purpose
- Keep public functions at top, private helpers at bottom

## Naming Conventions

| File | Module |
|------|--------|
| `goal_json.ex` | `HeadsUpWeb.Api.GoalJSON` |
| `category_json.ex` | `HeadsUpWeb.Api.CategoryJSON` |
| `user_json.ex` | `HeadsUpWeb.Api.UserJSON` |
| `activity_json.ex` | `HeadsUpWeb.Api.ActivityJSON` |
| `error_json.ex` | `HeadsUpWeb.ErrorJSON` |

## Render Functions

### Index (List) Response

```elixir
@doc """
Renders a list of goals.
"""
def index(%{goals: goals, current_user_id: current_user_id}) do
  %{
    data: for(goal <- goals, do: goal_data(goal, current_user_id)),
    meta: %{
      count: length(goals),
      page_info: %{
        has_next_page: false,
        has_previous_page: false
      }
    }
  }
end
```

**Pattern**: Use `for` comprehension to transform list items, include `meta` for pagination info.

### Show (Single Resource) Response

```elixir
@doc """
Renders a single goal.
"""
def show(%{goal: goal, current_user_id: current_user_id}) do
  %{data: goal_data(goal, current_user_id)}
end
```

### Create Response

```elixir
@doc """
Renders goal created/updated response.
"""
def create(%{goal: goal, current_user_id: current_user_id}) do
  %{
    data: goal_data(goal, current_user_id),
    message: "Goal created successfully"
  }
end
```

### Delete Response

```elixir
@doc """
Renders goal deletion response.
"""
def delete(%{message: message}) do
  %{
    message: message,
    success: true
  }
end
```

### Action Success Response

```elixir
@doc """
Renders action success response (like, subscribe, etc.).
"""
def action_success(%{message: message}) do
  %{
    message: message,
    success: true
  }
end
```

### Error Response

```elixir
@doc """
Renders error response.
"""
def error(%{message: message}) do
  %{
    error: %{
      message: message
    },
    success: false
  }
end
```

### Changeset Error Response

```elixir
@doc """
Renders changeset error response.
"""
def changeset_error(%{changeset: changeset}) do
  %{
    error: %{
      message: "Validation failed",
      details: translate_errors(changeset)
    },
    success: false
  }
end
```

## Data Transformation Helpers

### Main Resource Transformer

```elixir
defp goal_data(goal, current_user_id) do
  %{
    id: goal.id,
    title: goal.title,
    description: goal.description,
    big_description: goal.big_description,
    status: goal.status,
    privacy: goal.privacy,
    progress: goal.progress,
    target_date: goal.target_date,
    image_path: goal.image_path,
    failure_reason: goal.failure_reason,
    failed_at: goal.failed_at,
    is_frozen: goal.is_frozen,

    # Timestamps
    created_at: goal.inserted_at,
    updated_at: goal.updated_at,

    # Related resources (conditional)
    category: if(goal.group, do: category_data(goal.group), else: nil),
    creator: if(goal.user, do: user_data(goal.user), else: nil),

    # Computed fields
    likes_count: Map.get(goal, :like_count, 0),
    subscribers_count: Map.get(goal, :subscriber_count, 0),

    # User-specific data (if authenticated)
    user_interactions: if(current_user_id, do: user_interactions(goal, current_user_id), else: nil),

    # Related collections
    steps: if(goal.goal_steps, do: Enum.map(goal.goal_steps, &step_data/1), else: []),
    recent_posts: if(goal.goal_posts, do: Enum.take(goal.goal_posts, 5) |> Enum.map(&post_data/1), else: [])
  }
end
```

**Pattern**:
- Rename `inserted_at` to `created_at` for API consistency
- Use `Map.get/3` with default for computed fields
- Check for nil before transforming related resources
- Limit collections (e.g., `recent_posts` takes only 5)

### Nested Resource Transformers

```elixir
defp category_data(group) do
  %{
    id: group.id,
    name: group.name,
    description: group.description,
    image_path: group.image_path
  }
end

defp user_data(user) do
  %{
    id: user.id,
    name: user.name,
    username: user.user_name,
    level: user.level,
    image_path: user.image_path,
    bio: user.bio
  }
end

defp step_data(step) do
  %{
    id: step.id,
    title: step.title,
    completed: step.completed,
    order: step.order,
    created_at: step.inserted_at,
    updated_at: step.updated_at
  }
end

defp post_data(post) do
  %{
    id: post.id,
    content: post.content,
    post_type: post.post_type,
    image_path: post.image_path,
    created_at: post.inserted_at,
    author: if(post.user, do: user_data(post.user), else: nil)
  }
end
```

### User Interaction Data

```elixir
defp user_interactions(goal, current_user_id) do
  is_liked = Enum.any?(goal.goal_likes || [], &(&1.user_id == current_user_id))
  is_subscribed = Enum.any?(goal.goal_subscriptions || [], &(&1.user_id == current_user_id))
  is_owner = goal.user_id == current_user_id

  %{
    is_liked: is_liked,
    is_subscribed: is_subscribed,
    is_owner: is_owner,
    can_edit: is_owner,
    can_delete: is_owner
  }
end
```

**Pattern**: Include capability flags (`can_edit`, `can_delete`) based on ownership.

## Error Translation

```elixir
defp translate_errors(changeset) do
  Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
    Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end)
end
```

**Pattern**: Use `traverse_errors` to convert changeset errors to client-friendly format.

## Error HTML View

```elixir
defmodule HeadsUpWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.
  """
  use HeadsUpWeb, :html

  embed_templates "error_html/*"

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
```

## Error JSON View

```elixir
defmodule HeadsUpWeb.ErrorJSON do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on JSON requests.
  """

  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
```

## Page HTML View

```elixir
defmodule HeadsUpWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.
  """
  use HeadsUpWeb, :html

  embed_templates "page_html/*"
end
```

**Pattern**: Use `embed_templates` to automatically load `.heex` templates from directory.

## Response Structure Conventions

### Success Response

```json
{
  "data": { ... },
  "message": "Optional success message",
  "success": true
}
```

### List Response

```json
{
  "data": [ ... ],
  "meta": {
    "count": 10,
    "page_info": {
      "has_next_page": true,
      "has_previous_page": false
    }
  }
}
```

### Error Response

```json
{
  "error": {
    "message": "Human readable error",
    "details": { ... }
  },
  "success": false
}
```

### Validation Error Response

```json
{
  "error": {
    "message": "Validation failed",
    "details": {
      "title": ["can't be blank"],
      "email": ["has invalid format"]
    }
  },
  "success": false
}
```
