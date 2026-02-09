# LiveView Style Guide

This style guide documents the patterns and conventions used in HeadsUp LiveView modules.

## Module Structure

### Standard Declaration

```elixir
defmodule HeadsUpWeb.GoalLive.Show do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Goals
```

**Pattern**: Use `HeadsUpWeb, :live_view` macro, alias contexts at top.

### Import Patterns for Components

```elixir
defmodule HeadsUpWeb.UsersLive.Show do
  use HeadsUpWeb, :live_view
  alias HeadsUp.{Accounts, Goals}
  import HeadsUpWeb.Components.GoalCard
  import HeadsUpWeb.Helpers.AvatarHelper
  import HeadsUpWeb.Components.CommitmentChart
```

**Pattern**: Import custom function components and helpers when used frequently.

## Mount Patterns

### Basic Mount with Authentication Check

```elixir
def mount(%{"id" => goal_id}, _session, socket) do
  try do
    {goal_id, _} = Integer.parse(goal_id)
    current_user = socket.assigns[:current_user]
    current_user_id = if current_user, do: current_user.id, else: nil

    goal = Goals.get_goal_with_post_likes!(goal_id, current_user_id)

    # Access control check
    can_access = goal.privacy == :public or (current_user && goal.user_id == current_user.id)

    if can_access do
      socket =
        socket
        |> assign(:goal, goal)
        |> assign(:current_user_id, current_user_id)
        |> assign(:is_owner, current_user && goal.user_id == current_user.id)
        # ... more assigns
      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Goal not found or you don't have permission to view it.")
       |> push_navigate(to: ~p"/goals")}
    end
  rescue
    Ecto.NoResultsError ->
      {:ok,
       socket
       |> put_flash(:error, "Goal not found.")
       |> push_navigate(to: ~p"/goals")}
  end
end
```

**Pattern**:
- Use try/rescue for resource loading
- Parse ID with `Integer.parse/1`
- Check `socket.assigns[:current_user]` with bracket notation (nil-safe)
- Check access before proceeding
- Redirect with flash on access denied

### Mount with Required Authentication

```elixir
def mount(_params, _session, socket) do
  current_user = socket.assigns.current_user  # Will fail if not authenticated
  current_user_id = current_user.id

  my_goals = Goals.list_goals_by_user(current_user_id)

  socket =
    socket
    |> assign(:my_goals, my_goals)
    |> assign(:current_user_id, current_user_id)

  {:ok, socket}
end
```

**Pattern**: For authenticated-only routes, access `current_user` with dot notation (guaranteed by route protection).

### Mount with Nil Check Redirect

```elixir
def mount(_params, _session, socket) do
  current_user = socket.assigns[:current_user]

  if is_nil(current_user) do
    socket =
      socket
      |> put_flash(:error, "You must be logged in to create goals.")
      |> push_navigate(to: ~p"/users/log_in")

    {:ok, socket}
  else
    # Normal mount logic
    {:ok, socket}
  end
end
```

### Mount with PubSub Subscription

```elixir
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(HeadsUp.PubSub, "user_activities")
  end

  {:ok,
   socket
   |> assign(:page_title, "Feed")
   |> assign(:feed_items, [])
   |> load_feed_items()}
end
```

**Pattern**: Only subscribe to PubSub when connected (avoid double subscription).

### Mount with Multiple Data Sources

```elixir
def mount(%{"username" => username}, _session, socket) do
  user = Accounts.get_user_by_username(username)

  # Fallback lookup patterns
  user =
    if is_nil(user) do
      cond do
        String.starts_with?(username, "user-") ->
          case Integer.parse(String.replace_prefix(username, "user-", "")) do
            {id, ""} -> Accounts.get_user(id)
            _ -> nil
          end
        true ->
          case Integer.parse(username) do
            {id, ""} -> Accounts.get_user(id)
            _ -> nil
          end
      end
    else
      user
    end

  if user do
    # Load additional data
    followers_count = Accounts.get_followers_count(user.id)
    # ... more data loading

    {:ok, socket |> assign(:user, user) |> assign(:followers_count, followers_count)}
  else
    {:ok,
     socket
     |> put_flash(:error, "User '#{username}' not found")
     |> push_navigate(to: ~p"/people")}
  end
end
```

**Pattern**: Support multiple URL formats (username, user-id, numeric id).

## Handle Event Patterns

### Toggle Operations

```elixir
def handle_event("toggle_like", _params, socket) do
  goal_id = socket.assigns.goal.id
  current_user_id = socket.assigns.current_user_id

  # Self-action prevention
  if socket.assigns.is_owner do
    {:noreply, put_flash(socket, :error, "You cannot like your own goal")}
  else
    if socket.assigns.user_liked do
      Goals.unlike_goal(goal_id, current_user_id)
      # Refresh and toggle state
      {:noreply, socket |> refresh_goal() |> assign(:user_liked, false)}
    else
      case Goals.like_goal(goal_id, current_user_id) do
        {:ok, _} ->
          {:noreply, socket |> refresh_goal() |> assign(:user_liked, true)}
        {:error, :cannot_like_own_goal} ->
          {:noreply, put_flash(socket, :error, "You cannot like your own goal")}
        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to like goal")}
      end
    end
  end
end
```

**Pattern**: Always check ownership for self-action prevention, handle error cases explicitly.

### Form Save with Action Dispatch

```elixir
def handle_event("save", %{"goal" => goal_params}, socket) do
  save_goal(socket, socket.assigns.action, goal_params)
end

defp save_goal(socket, :edit, goal_params) do
  case Goals.update_goal_with_ownership(socket.assigns.goal, goal_params, socket.assigns.current_user_id) do
    {:ok, _goal} ->
      {:noreply,
       socket
       |> put_flash(:info, "Goal updated successfully")
       |> push_navigate(to: socket.assigns.patch)}
    {:error, :unauthorized} ->
      {:noreply,
       socket
       |> put_flash(:error, "You are not authorized to edit this goal")
       |> push_navigate(to: socket.assigns.patch)}
    {:error, %Ecto.Changeset{} = changeset} ->
      {:noreply, assign(socket, :form, to_form(changeset))}
  end
end

defp save_goal(socket, :new, goal_params) do
  # ... create logic
end
```

**Pattern**: Dispatch to private functions based on action (`:new`, `:edit`).

### Tab Switching with URL Update

```elixir
def handle_event("switch_tab", %{"tab" => tab}, socket) do
  {:noreply, push_patch(socket, to: ~p"/connections?tab=#{tab}")}
end
```

### Data Parsing from Event Params

```elixir
def handle_event("toggle_step", %{"step-id" => step_id}, socket) do
  {step_id, _} = Integer.parse(step_id)
  step = Goals.get_goal_step!(step_id)
  # ... rest of handler
end

def handle_event("unfollow_user", %{"user_id" => user_id}, socket) do
  user_id = String.to_integer(user_id)
  # ... rest of handler
end
```

**Pattern**: Parse string IDs from events, use either `Integer.parse/1` or `String.to_integer/1`.

### Confirmation Dialog Actions

```elixir
def handle_event("delete_goal", %{"goal-id" => goal_id}, socket) do
  {goal_id, _} = Integer.parse(goal_id)
  goal = Goals.get_goal!(goal_id)

  if goal.user_id == socket.assigns.current_user_id do
    case Goals.delete_goal(goal) do
      {:ok, _} ->
        user_goals = Goals.list_goals_by_user(socket.assigns.current_user_id)
        {:noreply,
         socket
         |> assign(:user_goals, user_goals)
         |> put_flash(:info, "Goal deleted successfully")}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete goal")}
    end
  else
    {:noreply, put_flash(socket, :error, "You can only delete your own goals")}
  end
end
```

## Handle Params Pattern

```elixir
@impl true
def handle_params(params, _url, socket) do
  tab = Map.get(params, "tab", "following")
  {:noreply, assign(socket, :active_tab, tab)}
end
```

**Pattern**: Use `handle_params` for URL-based state (tabs, filters).

## Handle Info Pattern

```elixir
def handle_info({:user_activity, _activity}, socket) do
  # Refresh feed when new activity occurs
  {:noreply,
   socket
   |> assign(:feed_items, [])
   |> assign(:offset, 0)
   |> load_feed_items()}
end
```

**Pattern**: Handle PubSub messages with `handle_info`.

## Socket Assignment Patterns

### Chained Assigns

```elixir
socket =
  socket
  |> assign(:goal, goal)
  |> assign(:current_user_id, current_user_id)
  |> assign(:is_owner, current_user && goal.user_id == current_user.id)
  |> assign(:user_liked, current_user_id && Goals.user_liked_goal?(goal_id, current_user_id) || false)
  |> assign(:new_step_title, "")
  |> assign(:editing_step_id, nil)
```

### Computed Assigns

```elixir
# Safe association access
like_count = if Ecto.assoc_loaded?(goal.goal_likes), do: length(goal.goal_likes), else: 0
subscriber_count = if Ecto.assoc_loaded?(goal.goal_subscriptions), do: length(goal.goal_subscriptions), else: 0

goal =
  goal
  |> Map.put(:like_count, like_count)
  |> Map.put(:subscriber_count, subscriber_count)
```

### Form Assigns

```elixir
|> assign(:about_form, to_form(%{"about" => user.about || ""}))
|> assign(:bio_form, to_form(%{"bio" => user.bio || ""}))
```

### File Upload Configuration

```elixir
|> allow_upload(:avatar,
  accept: ~w(.jpg .jpeg .png),
  max_entries: 1,
  max_file_size: 5_000_000
)
```

## Render Patterns

### Inline Render

```elixir
def render(assigns) do
  ~H"""
  <div class="max-w-4xl mx-auto px-4">
    <!-- Component content -->
  </div>
  """
end
```

### Private Function Components Within LiveView

```elixir
defp following_tab(assigns) do
  ~H"""
  <div class="p-6">
    <!-- Tab-specific content -->
  </div>
  """
end

defp followers_tab(assigns) do
  ~H"""
  <div class="p-6">
    <!-- Tab-specific content -->
  </div>
  """
end
```

**Pattern**: Define private function components for reusable sections within the module.

## Helper Functions

### Status/Privacy Class Helpers

```elixir
defp status_class(:active), do: "bg-green-100 text-green-800 border border-green-200"
defp status_class(:completed), do: "bg-blue-100 text-blue-800 border border-blue-200"
defp status_class(:paused), do: "bg-yellow-100 text-yellow-800 border border-yellow-200"
defp status_class(:cancelled), do: "bg-red-100 text-red-800 border border-red-200"
defp status_class(:frozen), do: "bg-purple-100 text-purple-800 border border-purple-200"
defp status_class(:failed), do: "bg-red-100 text-red-800 border border-red-200"
defp status_class(_), do: "bg-gray-100 text-gray-800 border border-gray-200"

defp privacy_class(:public), do: "bg-green-100 text-green-700 border border-green-200"
defp privacy_class(:friends), do: "bg-blue-100 text-blue-700 border border-blue-200"
defp privacy_class(:private), do: "bg-orange-100 text-orange-700 border border-orange-200"
defp privacy_class(_), do: "bg-gray-100 text-gray-700 border border-gray-200"
```

**Pattern**: Use function clause matching for CSS class mapping.

### Data Loading Helpers

```elixir
defp load_connections(socket, user_id) do
  following = Accounts.list_following(user_id)
  followers = Accounts.list_followers(user_id)
  friends = Accounts.list_friends(user_id)

  socket
  |> assign(:following, following)
  |> assign(:followers, followers)
  |> assign(:friends, friends)
  |> assign(:following_count, length(following))
  |> assign(:followers_count, length(followers))
  |> assign(:friends_count, length(friends))
end

defp load_feed_items(socket) do
  current_user = socket.assigns.current_user
  limit = 20
  offset = socket.assigns.offset || 0

  new_items = FeedService.get_user_feed(current_user.id, limit: limit, offset: offset)
  existing_items = socket.assigns.feed_items || []

  socket
  |> assign(:feed_items, existing_items ++ new_items)
  |> assign(:offset, offset + limit)
  |> assign(:has_more, length(new_items) == limit)
end
```

### Time Formatting

```elixir
defp format_time_ago(datetime) do
  now = DateTime.utc_now()
  diff = DateTime.diff(now, datetime, :second)

  cond do
    diff < 60 -> "#{diff}s ago"
    diff < 3600 -> "#{div(diff, 60)}m ago"
    diff < 86400 -> "#{div(diff, 3600)}h ago"
    true -> "#{div(diff, 86400)}d ago"
  end
end
```

### Avatar Color Generation

```elixir
defp user_avatar_bg_class(name) do
  colors = [
    "bg-red-500", "bg-blue-500", "bg-green-500", "bg-yellow-500",
    "bg-purple-500", "bg-pink-500", "bg-indigo-500", "bg-orange-500"
  ]

  hash = :erlang.phash2(name || "")
  Enum.at(colors, rem(hash, length(colors)))
end
```

## @impl Annotations

```elixir
@impl true
def mount(_params, _session, socket)

@impl true
def handle_params(params, _url, socket)

@impl true
def handle_event("switch_tab", %{"tab" => tab}, socket)
```

**Pattern**: Use `@impl true` for LiveView callbacks when multiple callbacks are defined.

## Template Patterns in Render

### Conditional Rendering

```elixir
<%= if @current_user && @current_user.id == @user.id do %>
  <!-- Owner-only content -->
<% end %>

<%= if @can_view_details do %>
  <!-- Content for authorized viewers -->
<% else %>
  <!-- Restricted content placeholder -->
<% end %>
```

### Case Statements in Templates

```elixir
<%= case @active_tab do %>
  <% "following" -> %>
    <.following_tab users={@following} />
  <% "followers" -> %>
    <.followers_tab users={@followers} />
  <% "friends" -> %>
    <.friends_tab users={@friends} />
<% end %>

<%= case @goal.privacy do %>
  <% :public -> %> Public
  <% :friends -> %> Friends Only
  <% _ -> %> Private
<% end %>
```

### For Comprehensions

```elixir
<%= for item <- @feed_items do %>
  <div class="bg-white rounded-lg shadow-md p-6">
    <!-- Item content -->
  </div>
<% end %>

<div :for={goal <- @my_goals} class="bg-white rounded-lg">
  <!-- Goal card -->
</div>
```

**Pattern**: Use either `<%= for %>` or `:for` attribute syntax.

### Dynamic Class Bindings

```elixir
class={[
  "py-2 px-1 border-b-2 font-medium text-sm",
  if(@active_tab == "following",
    do: "border-blue-500 text-blue-600",
    else: "border-transparent text-gray-500 hover:text-gray-700")
]}

class={"px-2 py-1 rounded-full text-xs font-medium #{status_class(@goal.status)}"}
```
