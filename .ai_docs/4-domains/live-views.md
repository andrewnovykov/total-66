# LiveView Patterns - Domain Documentation

## Overview

LiveViews in HeadsUp provide real-time, interactive UI without writing JavaScript. The application uses the `use HeadsUpWeb, :live_view` macro which provides standard Phoenix LiveView functionality with verified routes.

## LiveView Files

| LiveView Module | File Path | Purpose |
|-----------------|-----------|---------|
| `HeadsUpWeb.GoalLive.Index` | `/lib/heads_up_web/live/goal_live/index.ex` | User's goal list |
| `HeadsUpWeb.GoalLive.Show` | `/lib/heads_up_web/live/goal_live/show.ex` | Goal detail view |
| `HeadsUpWeb.GoalLive.Edit` | `/lib/heads_up_web/live/goal_live/edit.ex` | Goal editing |
| `HeadsUpWeb.GoalLive.New` | `/lib/heads_up_web/live/goal_live/new.ex` | Goal creation |
| `HeadsUpWeb.UsersLive.Index` | `/lib/heads_up_web/live/users_live/index.ex` | User list |
| `HeadsUpWeb.UsersLive.Show` | `/lib/heads_up_web/live/users_live/show.ex` | User profile |
| `HeadsUpWeb.FeedLive.Index` | `/lib/heads_up_web/live/feed_live/index.ex` | Activity feed |
| `HeadsUpWeb.ConnectionsLive.Index` | `/lib/heads_up_web/live/connections_live/index.ex` | Following/friends |
| `HeadsUpWeb.MyGoalsLive.Index` | `/lib/heads_up_web/live/my_goals_live/index.ex` | My goals view |
| `HeadsUpWeb.Admin.GroupsLive.Index` | `/lib/heads_up_web/live/admin/groups_live/index.ex` | Admin categories |
| `HeadsUpWeb.ChallengeLive.Index` | `/lib/heads_up_web/live/challenge_live/index.ex` | Challenge listing (2-col grid with stats) |
| `HeadsUpWeb.ChallengeLive.Show` | `/lib/heads_up_web/live/challenge_live/show.ex` | Challenge/template detail, start, check-ins, phases |
| `HeadsUpWeb.ChallengeLive.Edit` | `/lib/heads_up_web/live/challenge_live/edit.ex` | Challenge editing |
| `HeadsUpWeb.ChallengeLive.New` | `/lib/heads_up_web/live/challenge_live/new.ex` | Create challenge |
| `HeadsUpWeb.ChallengeLive.MyChallenges` | `/lib/heads_up_web/live/challenge_live/my_challenges.ex` | User's active challenges |
| `HeadsUpWeb.Admin.ChallengeCategoriesLive.Index` | `/lib/heads_up_web/live/admin/challenge_categories_live/index.ex` | Admin challenge categories |
| `HeadsUpWeb.AllGoalsLive.Index` | `/lib/heads_up_web/live/all_goals_live/index.ex` | Browse all public goals |
| `HeadsUpWeb.GoalCategoryLive.Index` | `/lib/heads_up_web/live/goal_category_live/index.ex` | Goal categories/groups listing |
| `HeadsUpWeb.GoalCategoryLive.Show` | `/lib/heads_up_web/live/goal_category_live/show.ex` | Goals in a category |

## Module Structure

### Standard LiveView Pattern

```elixir
# File: /lib/heads_up_web/live/goal_live/index.ex
defmodule HeadsUpWeb.GoalLive.Index do
  use HeadsUpWeb, :live_view
  alias HeadsUp.Goals
  alias HeadsUp.GoalGroups

  def mount(_params, _session, socket) do
    # ...
    {:ok, socket}
  end

  def handle_event("event_name", params, socket) do
    # ...
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <!-- HEEx template -->
    """
  end
end
```

### LiveView with Context Imports

```elixir
# File: /lib/heads_up_web/live/users_live/show.ex
defmodule HeadsUpWeb.UsersLive.Show do
  use HeadsUpWeb, :live_view
  alias HeadsUp.{Accounts, Goals}
  import HeadsUpWeb.Components.GoalCard
  import HeadsUpWeb.Helpers.AvatarHelper
  import HeadsUpWeb.Components.CommitmentChart
  # ...
end
```

## Mount Pattern

### Basic Mount

```elixir
# File: /lib/heads_up_web/live/goal_live/index.ex
def mount(_params, _session, socket) do
  current_user_id = 1

  user_goals = Goals.list_goals_by_user(current_user_id)
  goal_groups = GoalGroups.get_goal_groups()

  socket =
    socket
    |> assign(:user_goals, user_goals)
    |> assign(:goal_groups, goal_groups)
    |> assign(:current_user_id, current_user_id)
    |> assign(:show_create_form, false)
    |> assign(:filter_status, "all")
    |> assign(:filter_privacy, "all")

  {:ok, socket}
end
```

### Mount with URL Parameters

```elixir
# File: /lib/heads_up_web/live/users_live/show.ex
def mount(%{"username" => username}, _session, socket) do
  user = Accounts.get_user_by_username(username)

  # Fallback to ID-based lookup
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
    # Load user data and assign to socket
    socket =
      socket
      |> assign(:user, user)
      |> assign(:followers_count, Accounts.get_followers_count(user.id))
      # ... more assigns

    {:ok, socket}
  else
    {:ok,
     socket
     |> put_flash(:error, "User '#{username}' not found")
     |> push_navigate(to: ~p"/people")}
  end
end
```

### Mount with File Uploads

```elixir
# File: /lib/heads_up_web/live/users_live/show.ex
def mount(%{"username" => username}, _session, socket) do
  # ... user lookup ...

  socket =
    socket
    |> assign(:user, user)
    |> allow_upload(:avatar,
      accept: ~w(.jpg .jpeg .png),
      max_entries: 1,
      max_file_size: 5_000_000
    )

  {:ok, socket}
end
```

## Assign Pattern

### Pipeline Assigns

```elixir
socket =
  socket
  |> assign(:user, user)
  |> assign(:user_level, user_level)
  |> assign(:followers_count, followers_count)
  |> assign(:following_count, following_count)
  |> assign(:friends_count, friends_count)
  |> assign(:user_goals, user_goals)
  |> assign(:is_following, is_following)
  |> assign(:friendship_status, friendship_status)
  |> assign(:can_follow, can_follow)
  |> assign(:can_view_private_content, can_view_private_content)
  |> assign(:chart_data, chart_data)
  |> assign(:activity_summary, activity_summary)
  |> assign(:editing_about, false)
  |> assign(:editing_bio, false)
  |> assign(:editing_avatar, false)
  |> assign(:about_form, to_form(%{"about" => user.about || ""}))
  |> assign(:bio_form, to_form(%{"bio" => user.bio || ""}))
```

### Conditional Assigns

```elixir
{is_following, friendship_status, can_follow} =
  if socket.assigns[:current_user] do
    current_user_id = socket.assigns.current_user.id
    is_following = Accounts.is_following?(current_user_id, user.id)
    are_friends = Accounts.are_friends?(current_user_id, user.id)

    friendship_status =
      cond do
        are_friends -> :friends
        req = Accounts.get_friend_request(current_user_id, user.id) ->
          if req.status == "pending", do: :request_sent, else: :none
        true -> :none
      end

    can_follow =
      case user.privacy do
        "public" -> true
        "private" -> false
        "friends_only" -> are_friends
        _ -> true
      end

    {is_following, friendship_status, can_follow}
  else
    {false, :none, user.privacy == "public" or user.privacy == nil}
  end
```

## Event Handling Pattern

### Simple Event

```elixir
# File: /lib/heads_up_web/live/goal_live/index.ex
def handle_event("show_create_form", _params, socket) do
  user_goals_count = length(socket.assigns.user_goals)

  if user_goals_count >= 2 do
    socket = put_flash(socket, :error, "You can only create maximum 2 goals.")
    {:noreply, socket}
  else
    {:noreply, assign(socket, :show_create_form, true)}
  end
end

def handle_event("hide_create_form", _params, socket) do
  {:noreply, assign(socket, :show_create_form, false)}
end
```

### Event with Parameters

```elixir
# File: /lib/heads_up_web/live/goal_live/index.ex
def handle_event("delete_goal", %{"goal-id" => goal_id}, socket) do
  {goal_id, _} = Integer.parse(goal_id)
  goal = Goals.get_goal!(goal_id)

  if goal.user_id == socket.assigns.current_user_id do
    case Goals.delete_goal(goal) do
      {:ok, _} ->
        user_goals = Goals.list_goals_by_user(socket.assigns.current_user_id)
        socket =
          socket
          |> assign(:user_goals, user_goals)
          |> put_flash(:info, "Goal deleted successfully")
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete goal")}
    end
  else
    {:noreply, put_flash(socket, :error, "You can only delete your own goals")}
  end
end
```

### Event with Context Result Handling

```elixir
# File: /lib/heads_up_web/live/users_live/show.ex
def handle_event("toggle_follow", _params, socket) do
  if socket.assigns[:current_user] do
    current_user_id = socket.assigns.current_user.id
    user_id = socket.assigns.user.id

    result =
      if socket.assigns.is_following do
        Accounts.unfollow_user(current_user_id, user_id)
      else
        Accounts.follow_user(current_user_id, user_id)
      end

    case result do
      {:ok, _} ->
        socket =
          socket
          |> assign(:is_following, !socket.assigns.is_following)
          |> assign(:followers_count, Accounts.get_followers_count(user_id))
        {:noreply, socket}

      {:error, :user_is_private} ->
        {:noreply, put_flash(socket, :error, "This user's profile is private")}

      {:error, :must_be_friends} ->
        {:noreply, put_flash(socket, :error, "You must be friends to follow this user")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Unable to follow/unfollow user")}
    end
  else
    {:noreply, put_flash(socket, :error, "You must be logged in to follow users")}
  end
end
```

### Form Event Handling

```elixir
# File: /lib/heads_up_web/live/users_live/show.ex
def handle_event("save_about", %{"about" => about}, socket) do
  if socket.assigns[:current_user] && socket.assigns.current_user.id == socket.assigns.user.id do
    case Accounts.update_user(socket.assigns.user, %{about: about}) do
      {:ok, updated_user} ->
        socket =
          socket
          |> assign(:user, updated_user)
          |> assign(:editing_about, false)
          |> put_flash(:info, "About section updated successfully")
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update about section")}
    end
  else
    {:noreply, socket}
  end
end
```

### File Upload Event

```elixir
# File: /lib/heads_up_web/live/users_live/show.ex
def handle_event("save_avatar", _params, socket) do
  if socket.assigns[:current_user] && socket.assigns.current_user.id == socket.assigns.user.id do
    case consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
           uploads_dir = Path.join("priv/static/uploads")
           File.mkdir_p!(uploads_dir)

           extension = Path.extname(path)
           filename =
             "avatar_#{socket.assigns.user.id}_#{System.unique_integer([:positive])}_#{System.os_time(:second)}#{extension}"
           dest_path = Path.join(uploads_dir, filename)

           case File.cp(path, dest_path) do
             :ok -> {:ok, "/uploads/#{filename}"}
             {:error, reason} -> {:error, "Failed to save avatar: #{inspect(reason)}"}
           end
         end) do
      [image_path] when is_binary(image_path) ->
        case Accounts.update_user(socket.assigns.user, %{image_path: image_path}) do
          {:ok, updated_user} ->
            socket =
              socket
              |> assign(:user, updated_user)
              |> assign(:editing_avatar, false)
              |> put_flash(:info, "Avatar updated successfully")
            {:noreply, socket}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to update avatar")}
        end

      [] ->
        {:noreply, put_flash(socket, :error, "Please select an image file")}
    end
  else
    {:noreply, socket}
  end
end
```

## Navigation Pattern

### Push Navigate

```elixir
def handle_event("view_goal", %{"goal-id" => goal_id}, socket) do
  {:noreply, push_navigate(socket, to: ~p"/goals/#{goal_id}")}
end

def handle_event("view_user", %{"user-id" => user_id}, socket) do
  user = Accounts.get_user(user_id)
  if user do
    {:noreply, push_navigate(socket, to: ~p"/people/#{user.user_name}")}
  else
    {:noreply, socket}
  end
end
```

### Redirect on Error

```elixir
if user do
  {:ok, socket |> assign(:user, user)}
else
  {:ok,
   socket
   |> put_flash(:error, "User '#{username}' not found")
   |> push_navigate(to: ~p"/people")}
end
```

## Embedded Template Pattern

LiveViews define templates inline using `~H` sigil:

```elixir
# File: /lib/heads_up_web/live/goal_live/index.ex
def render(assigns) do
  ~H"""
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <div class="bg-white shadow-sm border-b">
      <div class="max-w-7xl mx-auto px-4 py-6">
        <h1 class="text-3xl font-bold text-[#0d141c]">My Goals</h1>
        <button phx-click="show_create_form" class="...">
          Create Goal
        </button>
      </div>
    </div>

    <!-- Flash Messages -->
    <%= if Phoenix.Flash.get(@flash, :info) do %>
      <div class="bg-green-100 ...">
        <%= Phoenix.Flash.get(@flash, :info) %>
      </div>
    <% end %>

    <!-- Goals Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div :for={goal <- @user_goals} class="bg-white rounded-lg ...">
        <.link navigate={~p"/goals/#{goal.id}"}>
          <%= goal.title %>
        </.link>
      </div>
    </div>
  </div>
  """
end
```

## Component Usage in Templates

### Live Component

```elixir
<.live_component
  module={HeadsUpWeb.GoalLive.FormComponent}
  id="create-goal"
  action="new"
  goal={%HeadsUp.Goal{}}
  current_user_id={@current_user_id}
  goal_groups={@goal_groups}
  patch={~p"/my-goals"}
/>
```

### Function Component

```elixir
# Import in module
import HeadsUpWeb.Components.GoalCard
import HeadsUpWeb.Components.CommitmentChart

# Use in template
<.goal_card
  goal={goal}
  show_category={true}
  show_creator={false}
  clickable={true}
  current_user_id={if @current_user, do: @current_user.id, else: nil}
/>

<.commitment_chart
  chart_data={@chart_data}
  activity_summary={@activity_summary}
  user={@user}
  user_level={@user_level}
/>
```

## Helper Functions Pattern

Private helper functions for rendering logic:

```elixir
# File: /lib/heads_up_web/live/goal_live/index.ex
defp filter_goals(goals, status_filter, privacy_filter) do
  goals
  |> filter_by_status(status_filter)
  |> filter_by_privacy(privacy_filter)
end

defp filter_by_status(goals, "all"), do: goals
defp filter_by_status(goals, status) do
  status_atom = String.to_atom(status)
  Enum.filter(goals, &(&1.status == status_atom))
end

defp filter_by_privacy(goals, "all"), do: goals
defp filter_by_privacy(goals, privacy) do
  privacy_atom = String.to_atom(privacy)
  Enum.filter(goals, &(&1.privacy == privacy_atom))
end

defp status_class(:active), do: "bg-green-100 text-green-800"
defp status_class(:completed), do: "bg-blue-100 text-blue-800"
defp status_class(:paused), do: "bg-yellow-100 text-yellow-800"
defp status_class(:cancelled), do: "bg-red-100 text-red-800"
defp status_class(_), do: "bg-gray-100 text-gray-800"
```

## Architectural Constraints

1. **Context Calls**: Call context modules for data operations, never Repo directly
2. **Socket Assigns**: All state stored in socket assigns, no module attributes for state
3. **Embedded Templates**: Templates defined via `render/1` function with `~H` sigil
4. **Event Handlers**: All user interactions go through `handle_event/3`
5. **Fast Mount**: Mount should be fast; defer expensive operations to connected state
