# Real-Time Patterns - Domain Documentation

## Overview

HeadsUp uses Phoenix PubSub for real-time updates. Currently, the application primarily uses PubSub for LiveView connectivity management (disconnecting sessions on logout). The infrastructure is in place for more extensive real-time features like activity feeds and notifications.

## PubSub Configuration

### Endpoint Configuration

```elixir
# File: /lib/heads_up_web/endpoint.ex
defmodule HeadsUpWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :heads_up

  @session_options [
    store: :cookie,
    key: "_heads_up_key",
    signing_salt: "...",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # ...
end
```

### Application PubSub

```elixir
# File: /lib/heads_up/application.ex
defmodule HeadsUp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HeadsUpWeb.Telemetry,
      HeadsUp.Repo,
      {DNSCluster, query: Application.get_env(:heads_up, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HeadsUp.PubSub},  # <-- PubSub configured here
      {Finch, name: HeadsUp.Finch},
      HeadsUpWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: HeadsUp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # ...
end
```

## LiveView Session Broadcasting

### Disconnect on Logout

```elixir
# File: /lib/heads_up_web/user_auth.ex
def log_out_user(conn) do
  user_token = get_session(conn, :user_token)
  user_token && Auth.delete_user_session_token(user_token)

  # Broadcast disconnect to all LiveView sessions for this user
  if live_socket_id = get_session(conn, :live_socket_id) do
    HeadsUpWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
  end

  conn
  |> renew_session()
  |> delete_resp_cookie(@remember_me_cookie)
  |> redirect(to: ~p"/")
end
```

### Socket ID in Session

```elixir
# File: /lib/heads_up_web/user_auth.ex
defp put_token_in_session(conn, token) do
  conn
  |> put_session(:user_token, token)
  |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
end
```

## Potential Real-Time Patterns

### Subscribe Pattern for LiveViews

The following pattern can be used when implementing real-time updates:

```elixir
# Example pattern for activity feed real-time updates
defmodule HeadsUpWeb.FeedLive.Index do
  use HeadsUpWeb, :live_view

  @topic "user_activities"

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to PubSub topic when connected
      Phoenix.PubSub.subscribe(HeadsUp.PubSub, @topic)

      # Subscribe to user-specific topic
      if socket.assigns.current_user do
        user_topic = "user:#{socket.assigns.current_user.id}"
        Phoenix.PubSub.subscribe(HeadsUp.PubSub, user_topic)
      end
    end

    {:ok, socket}
  end

  def handle_info({:new_activity, activity}, socket) do
    # Handle incoming activity broadcast
    activities = [activity | socket.assigns.activities]
    {:noreply, assign(socket, :activities, activities)}
  end
end
```

### Broadcast Pattern for Services

```elixir
# Example pattern for broadcasting activities
defmodule HeadsUp.ActivityService do
  # When tracking activity, broadcast to relevant topics
  def track_activity(user_id, activity_type, opts \\ []) do
    # ... create activity record ...

    # Broadcast to followers
    broadcast_activity_to_followers(user_id, activity)

    {:ok, activity}
  end

  defp broadcast_activity_to_followers(user_id, activity) do
    # Get user's followers
    followers = HeadsUp.Accounts.list_followers(user_id)

    # Broadcast to each follower's topic
    Enum.each(followers, fn follower ->
      Phoenix.PubSub.broadcast(
        HeadsUp.PubSub,
        "user:#{follower.id}",
        {:new_activity, activity}
      )
    end)
  end
end
```

## Topic Naming Conventions

Based on the architectural domains document, the following topic naming conventions should be used:

| Topic Pattern | Purpose |
|---------------|---------|
| `user_activities` | Global activity feed |
| `user:#{user_id}` | User-specific notifications |
| `goals:#{goal_id}` | Goal-specific updates |
| `users_sessions:#{token}` | User session management |

## Handle Info Pattern

```elixir
# Handle PubSub messages in LiveViews
def handle_info({:new_activity, activity}, socket) do
  activities = [activity | socket.assigns.activities]
  {:noreply, assign(socket, :activities, Enum.take(activities, 50))}
end

def handle_info({:goal_updated, goal}, socket) do
  if goal.id == socket.assigns.goal.id do
    {:noreply, assign(socket, :goal, goal)}
  else
    {:noreply, socket}
  end
end

def handle_info({:new_like, %{goal_id: goal_id}}, socket) do
  if goal_id == socket.assigns.goal.id do
    goal = Goals.get_goal!(goal_id)
    {:noreply, assign(socket, :goal, goal)}
  else
    {:noreply, socket}
  end
end
```

## Conditional Subscription Pattern

```elixir
def mount(_params, _session, socket) do
  # Only subscribe when connected (not during static render)
  if connected?(socket) do
    Phoenix.PubSub.subscribe(HeadsUp.PubSub, "some_topic")
  end

  {:ok, socket}
end
```

## Current Usage

Currently, HeadsUp uses PubSub primarily for:

1. **Session Management**: Broadcasting disconnect signals when users log out
2. **LiveView Connectivity**: Standard Phoenix LiveView socket connections

The infrastructure is in place for extending real-time features to include:
- Activity feed updates
- Goal progress notifications
- Social interaction notifications (likes, follows, comments)
- Online status indicators

## Architectural Constraints

1. **Topic Naming**: Use descriptive topic strings (`"user_activities"`, `"goals:#{id}"`)
2. **Subscribe on Connect**: Subscribe in mount when `connected?(socket)` is true
3. **Handle Info**: Handle PubSub messages in `handle_info/2`
4. **Non-Blocking Broadcasts**: Broadcasts should not block main operations
5. **Local PubSub**: Uses local Phoenix.PubSub, no distributed Redis
