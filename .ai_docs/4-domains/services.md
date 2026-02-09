# Service Modules - Domain Patterns

## Overview

Service modules in HeadsUp handle complex business logic and cross-cutting concerns that span multiple contexts. They are stateless modules (no GenServer) that encapsulate calculations, transformations, and multi-step operations.

## Service Files

| Service Module | File Path | Primary Responsibility |
|----------------|-----------|----------------------|
| `HeadsUp.ActivityService` | `/lib/heads_up/activity_service.ex` | XP rewards, level progression, activity tracking |
| `HeadsUp.FeedService` | `/lib/heads_up/feed_service.ex` | Social feed generation, commitment charts |

## Module Structure

### ActivityService Pattern

```elixir
# File: /lib/heads_up/activity_service.ex
defmodule HeadsUp.ActivityService do
  alias HeadsUp.{Repo, UserActivity, UserLevel, Users}
  import Ecto.Query

  @level_thresholds %{
    1 => {0, 100, "Seastar"},
    2 => {100, 250, "Seastar"},
    # ... 40 levels total
    40 => {39100, 999_999, "Legendary Shark"}
  }

  @xp_rewards %{
    "goal_created" => 50,
    "goal_completed" => 1000,
    "goal_failed" => -200,
    "goal_frozen" => -50,
    "goal_deleted" => -100,
    "goal_updated" => 10,
    "post_created" => 25,
    "post_liked" => 2,
    "post_received_like" => 3,
    "user_followed" => 5,
    "user_received_follow" => 5,
    "friend_request_sent" => 5,
    "friend_request_accepted" => 10,
    "daily_login" => 5,
    "goal_step_completed" => 15
  }
  # ...
end
```

### FeedService Pattern

```elixir
# File: /lib/heads_up/feed_service.ex
defmodule HeadsUp.FeedService do
  alias HeadsUp.{Repo, UserActivity, Users, UserFollow, Friendship}
  import Ecto.Query
  # ...
end
```

## Module Attributes for Configuration

Services use module attributes (`@`) for configuration data:

```elixir
# File: /lib/heads_up/activity_service.ex
@level_thresholds %{
  1 => {0, 100, "Seastar"},
  2 => {100, 250, "Seastar"},
  3 => {250, 400, "Seastar"},
  4 => {400, 600, "Seastar"},
  5 => {600, 850, "Seastar"},
  6 => {850, 1150, "Hermit Crab"},
  # ...continues through 40 levels
}

@xp_rewards %{
  "goal_created" => 50,
  "goal_completed" => 1000,
  "goal_failed" => -200,
  # ... all activity types with XP values
}
```

## Transaction Wrapping Pattern

Complex operations that update multiple records use `Repo.transaction`:

```elixir
# File: /lib/heads_up/activity_service.ex
def track_activity(user_id, activity_type, opts \\ []) do
  xp_change = Map.get(@xp_rewards, activity_type, 0)

  activity_attrs = %{
    user_id: user_id,
    activity_type: activity_type,
    xp_change: xp_change,
    description: Keyword.get(opts, :description),
    goal_id: Keyword.get(opts, :goal_id),
    post_id: Keyword.get(opts, :post_id),
    like_id: Keyword.get(opts, :like_id),
    follow_id: Keyword.get(opts, :follow_id),
    metadata: Keyword.get(opts, :metadata, %{})
  }

  Repo.transaction(fn ->
    # Create activity record
    {:ok, activity} =
      %UserActivity{}
      |> UserActivity.changeset(activity_attrs)
      |> Repo.insert()

    # Update user XP and level
    update_user_xp_and_level(user_id, xp_change)

    activity
  end)
end
```

## Public and Private Function Pattern

Services expose public functions and use private helpers for calculations:

```elixir
# File: /lib/heads_up/activity_service.ex

# Public function
def update_user_xp_and_level(user_id, xp_change) do
  user = Repo.get!(Users, user_id)
  current_xp = user.xp || 0
  new_xp = max(0, current_xp + xp_change)

  # Calculate new level
  {new_level, level_name} = calculate_level_from_xp(new_xp)

  # Update user
  user
  |> Users.changeset(%{xp: new_xp, level: new_level})
  |> Repo.update!()

  # Update or create user_level record
  case Repo.get_by(UserLevel, user_id: user_id) do
    nil ->
      %UserLevel{}
      |> UserLevel.changeset(%{
        user_id: user_id,
        level: new_level,
        xp: new_xp,
        level_name: level_name
      })
      |> Repo.insert!()

    user_level ->
      user_level
      |> UserLevel.changeset(%{
        level: new_level,
        xp: new_xp,
        level_name: level_name
      })
      |> Repo.update!()
  end

  {new_level, new_xp, level_name}
end

# Private helper - pure calculation, no side effects
defp calculate_level_from_xp(xp) do
  Enum.find(@level_thresholds, fn {_level, {min_xp, max_xp, _name}} ->
    xp >= min_xp and xp < max_xp
  end)
  |> case do
    {level, {_min, _max, name}} -> {level, name}
    nil -> {40, "Legendary Shark"}
  end
end
```

## Query Building in Services

Services build complex queries for data retrieval:

```elixir
# File: /lib/heads_up/feed_service.ex
def get_user_feed(user_id, opts \\ []) do
  limit = Keyword.get(opts, :limit, 20)
  offset = Keyword.get(opts, :offset, 0)

  # Get IDs of users that the current user follows
  following_ids =
    from(uf in UserFollow,
      where: uf.follower_id == ^user_id,
      select: uf.following_id
    )
    |> Repo.all()

  # Get friend IDs
  friend_ids =
    from(f in Friendship,
      where: (f.user_id == ^user_id or f.friend_id == ^user_id) and f.status == "accepted",
      select:
        fragment(
          "CASE WHEN ? = ? THEN ? ELSE ? END",
          f.user_id,
          ^user_id,
          f.friend_id,
          f.user_id
        )
    )
    |> Repo.all()

  # Combine following and friends
  feed_user_ids = Enum.uniq(following_ids ++ friend_ids)
  all_user_ids = [user_id | feed_user_ids]

  # Get activities from followed users and friends
  activities =
    from(a in UserActivity,
      join: u in Users,
      on: a.user_id == u.id,
      where: a.user_id in ^all_user_ids,
      where:
        a.activity_type in [
          "goal_created",
          "goal_completed",
          "goal_failed",
          "post_created",
          "user_followed",
          "friend_request_accepted"
        ],
      order_by: [desc: a.inserted_at],
      limit: ^limit,
      offset: ^offset,
      preload: [:user, :goal, :post],
      select: a
    )
    |> Repo.all()

  # Format activities for display
  Enum.map(activities, &format_activity_for_feed/1)
end
```

## Data Transformation Functions

Services include private functions for data transformation:

```elixir
# File: /lib/heads_up/feed_service.ex
defp format_activity_for_feed(activity) do
  base_data = %{
    id: activity.id,
    user: activity.user,
    activity_type: activity.activity_type,
    description: activity.description,
    xp_change: activity.xp_change,
    inserted_at: activity.inserted_at,
    goal: activity.goal,
    post: activity.post
  }

  # Generate user-friendly description
  user_friendly_description =
    case activity.activity_type do
      "goal_created" ->
        if activity.goal do
          "created a new goal: \"#{activity.goal.title}\""
        else
          "created a new goal"
        end

      "goal_completed" ->
        if activity.goal do
          "completed their goal: \"#{activity.goal.title}\""
        else
          "completed a goal"
        end

      # ... other cases
    end

  Map.put(base_data, :user_friendly_description, user_friendly_description)
end
```

## Chart Data Generation

Services generate data structures for UI visualization:

```elixir
# File: /lib/heads_up/feed_service.ex
def get_commitment_chart_data(user_id, year) do
  start_date = Date.new!(year, 1, 1)
  end_date = Date.new!(year, 12, 31)

  activities =
    from(a in UserActivity,
      where: a.user_id == ^user_id,
      where: fragment("DATE(?)", a.inserted_at) >= ^start_date,
      where: fragment("DATE(?)", a.inserted_at) <= ^end_date,
      select: %{
        date: fragment("DATE(?)", a.inserted_at),
        xp_change: a.xp_change
      }
    )
    |> Repo.all()

  # Group by date and sum XP changes
  daily_data =
    activities
    |> Enum.group_by(& &1.date)
    |> Enum.map(fn {date, day_activities} ->
      total_xp = Enum.sum(Enum.map(day_activities, & &1.xp_change))
      intensity = calculate_xp_intensity(total_xp)

      %{
        date: date,
        total_xp: total_xp,
        intensity: intensity,
        activity_count: length(day_activities)
      }
    end)

  # Fill in missing dates with 0 activity
  fill_missing_dates(daily_data, start_date, end_date)
end

defp calculate_xp_intensity(xp) do
  cond do
    xp >= 500 -> 4  # Very high
    xp >= 200 -> 3  # High
    xp >= 50 -> 2   # Medium
    xp > 0 -> 1     # Low
    true -> 0       # None
  end
end
```

## Streak Calculation Pattern

Services calculate streaks from activity data:

```elixir
# File: /lib/heads_up/activity_service.ex
defp calculate_current_streak(user_id) do
  today = Date.utc_today()

  # Get all dates with activity, starting from today and going backwards
  activity_dates =
    from(a in UserActivity,
      where: a.user_id == ^user_id,
      select: fragment("DATE(?)", a.inserted_at),
      distinct: true,
      order_by: [desc: fragment("DATE(?)", a.inserted_at)]
    )
    |> Repo.all()

  if Enum.empty?(activity_dates) do
    0
  else
    count_consecutive_days(activity_dates, today, 0)
  end
end

defp count_consecutive_days([], _current_date, count), do: count

defp count_consecutive_days([date | rest], current_date, count) do
  if Date.diff(current_date, date) == count do
    count_consecutive_days(rest, current_date, count + 1)
  else
    count
  end
end
```

## Statistics Aggregation

Services aggregate multiple statistics into summary maps:

```elixir
# File: /lib/heads_up/activity_service.ex
def get_user_stats(user_id) do
  user_level =
    Repo.get_by(UserLevel, user_id: user_id) ||
      %UserLevel{level: 1, xp: 0, level_name: "Seastar"}

  total_goals =
    from(a in UserActivity,
      where: a.user_id == ^user_id and a.activity_type == "goal_created",
      select: count(a.id)
    )
    |> Repo.one()

  completed_goals =
    from(a in UserActivity,
      where: a.user_id == ^user_id and a.activity_type == "goal_completed",
      select: count(a.id)
    )
    |> Repo.one()

  # Calculate completion rate
  completion_rate =
    if total_goals > 0 do
      Float.round(completed_goals / total_goals * 100, 1)
    else
      0.0
    end

  current_streak = calculate_current_streak(user_id)
  longest_streak = calculate_longest_streak(user_id)

  %{
    level: user_level.level,
    level_name: user_level.level_name,
    xp: user_level.xp,
    next_level_xp: get_next_level_xp(user_level.level),
    total_goals: total_goals,
    completed_goals: completed_goals,
    completion_rate: completion_rate,
    total_posts: total_posts,
    total_likes_given: total_likes_given,
    total_likes_received: total_likes_received,
    current_streak: current_streak,
    longest_streak: longest_streak
  }
end
```

## Architectural Constraints

1. **Stateless**: Services are stateless modules, no GenServer state
2. **Single Responsibility**: Each service handles one domain concern
3. **Pure Helpers**: Private functions are pure; side effects happen in public functions
4. **Transaction Wrapping**: Complex operations use `Repo.transaction` for atomicity
5. **Module Attributes**: Configuration data stored in `@` attributes
