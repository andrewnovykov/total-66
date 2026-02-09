# Service Module Style Guide

This style guide documents the patterns and conventions used in HeadsUp service modules.

## Service vs Context

In HeadsUp, services differ from contexts:
- **Contexts**: CRUD operations for specific domain entities
- **Services**: Cross-cutting concerns, complex business logic, aggregations

## Module Structure

### Import and Alias Pattern

```elixir
defmodule HeadsUp.ActivityService do
  alias HeadsUp.{Repo, UserActivity, UserLevel, Users}
  import Ecto.Query
```

**Pattern**: Group aliases with `{}` syntax, import query separately.

## Module Attributes for Configuration

### Threshold Configuration

```elixir
@level_thresholds %{
  1 => {0, 100, "Seastar"},
  2 => {100, 250, "Seastar"},
  3 => {250, 400, "Seastar"},
  # ... continues to level 40
  40 => {39100, 999_999, "Legendary Shark"}
}
```

**Pattern**: Use maps with tuple values for level/tier systems with min, max, and display name.

### Reward Configuration

```elixir
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
```

**Pattern**: String keys for activity types, integer values for rewards (negative for penalties).

## Activity Tracking Pattern

### Main Tracking Function

```elixir
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
    {:ok, activity} =
      %UserActivity{}
      |> UserActivity.changeset(activity_attrs)
      |> Repo.insert()

    update_user_xp_and_level(user_id, xp_change)

    activity
  end)
end
```

**Pattern**:
- Use keyword list for optional parameters
- Wrap related operations in `Repo.transaction`
- Return the created activity

## Level Calculation Pattern

### XP to Level Conversion

```elixir
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

**Pattern**: Use `Enum.find` with destructuring for threshold lookups, provide default for max level.

### User Level Update

```elixir
def update_user_xp_and_level(user_id, xp_change) do
  user = Repo.get!(Users, user_id)
  current_xp = user.xp || 0
  new_xp = max(0, current_xp + xp_change)

  {new_level, level_name} = calculate_level_from_xp(new_xp)

  # Update user
  user
  |> Users.changeset(%{xp: new_xp, level: new_level})
  |> Repo.update!()

  # Update or create user_level record
  case Repo.get_by(UserLevel, user_id: user_id) do
    nil ->
      %UserLevel{}
      |> UserLevel.changeset(%{user_id: user_id, level: new_level, xp: new_xp, level_name: level_name})
      |> Repo.insert!()
    user_level ->
      user_level
      |> UserLevel.changeset(%{level: new_level, xp: new_xp, level_name: level_name})
      |> Repo.update!()
  end

  {new_level, new_xp, level_name}
end
```

**Pattern**: Use `max(0, ...)` to prevent negative XP, update both user and user_level tables.

## Feed Service Patterns

### Feed Query with Multiple Sources

```elixir
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

  # Get friend IDs using CASE fragment
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

  # Combine and deduplicate
  feed_user_ids = Enum.uniq(following_ids ++ friend_ids)
  all_user_ids = [user_id | feed_user_ids]  # Include self

  # Query activities
  from(a in UserActivity,
    join: u in Users, on: a.user_id == u.id,
    where: a.user_id in ^all_user_ids,
    where: a.activity_type in ["goal_created", "goal_completed", "goal_failed", "post_created", ...],
    order_by: [desc: a.inserted_at],
    limit: ^limit,
    offset: ^offset,
    preload: [:user, :goal, :post]
  )
  |> Repo.all()
  |> Enum.map(&format_activity_for_feed/1)
end
```

**Pattern**: Aggregate multiple relationship sources, use SQL CASE fragment for bidirectional relationships.

### Function Overloading for Pagination

```elixir
def get_user_feed(user_id, opts \\ [])  # Keyword list version

def get_user_feed(user_id, page, limit) do  # Positional argument version
  offset = (page - 1) * limit
  get_user_feed(user_id, limit: limit, offset: offset)
end
```

**Pattern**: Provide both keyword and positional argument interfaces.

## Chart Data Generation

### Date-Based Aggregation

```elixir
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

  # Group by date and sum XP
  daily_data =
    activities
    |> Enum.group_by(& &1.date)
    |> Enum.map(fn {date, day_activities} ->
      total_xp = Enum.sum(Enum.map(day_activities, & &1.xp_change))
      %{
        date: date,
        total_xp: total_xp,
        intensity: calculate_xp_intensity(total_xp),
        activity_count: length(day_activities)
      }
    end)

  fill_missing_dates(daily_data, start_date, end_date)
end
```

**Pattern**: Use SQL `fragment("DATE(?)", ...)` for date extraction, fill gaps for complete ranges.

### Intensity Calculation

```elixir
defp calculate_xp_intensity(xp) do
  cond do
    xp >= 500 -> 4  # Very high
    xp >= 200 -> 3  # High
    xp >= 50 -> 2   # Medium
    xp > 0 -> 1     # Low
    true -> 0       # None
  end
end

defp calculate_intensity(activity_count) do
  cond do
    activity_count == 0 -> 0
    activity_count <= 2 -> 1
    activity_count <= 5 -> 2
    activity_count <= 10 -> 3
    true -> 4
  end
end
```

**Pattern**: Use `cond` for multi-threshold intensity calculations.

## Streak Calculation

### Current Streak

```elixir
defp calculate_current_streak(user_id) do
  today = Date.utc_today()

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

**Pattern**: Use recursive function with accumulator for streak counting.

### Longest Streak

```elixir
defp find_longest_consecutive_sequence(dates) do
  dates
  |> Enum.with_index()
  |> Enum.chunk_while(
    {0, 0, nil},
    fn {date, _index}, {current_length, max_length, prev_date} ->
      cond do
        prev_date == nil ->
          {:cont, {1, max(1, max_length), date}}
        Date.diff(date, prev_date) == 1 ->
          new_length = current_length + 1
          {:cont, {new_length, max(new_length, max_length), date}}
        true ->
          {:cont, {1, max_length, date}}
      end
    end,
    fn {_current_length, max_length, _prev_date} -> {:cont, max_length, []} end
  )
  |> Enum.max(fn -> 0 end)
end
```

**Pattern**: Use `Enum.chunk_while` with accumulator tuple for complex sequence analysis.

## Feed Item Formatting

### Activity to User-Friendly Description

```elixir
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

  user_friendly_description =
    case activity.activity_type do
      "goal_created" ->
        if activity.goal, do: "created a new goal: \"#{activity.goal.title}\"", else: "created a new goal"
      "goal_completed" ->
        if activity.goal, do: "completed their goal: \"#{activity.goal.title}\"", else: "completed a goal"
      "goal_failed" ->
        if activity.goal, do: "failed their goal: \"#{activity.goal.title}\"", else: "failed a goal"
      "post_created" ->
        if activity.post && activity.goal, do: "posted an update in \"#{activity.goal.title}\"", else: "created a new post"
      "user_followed" ->
        "started following someone new"
      "friend_request_accepted" ->
        "made a new friend"
      _ ->
        String.replace(activity.activity_type, "_", " ")
    end

  Map.put(base_data, :user_friendly_description, user_friendly_description)
end
```

**Pattern**: Use case matching with nil checks for conditional formatting.

## Public Wrappers for Private Functions

```elixir
# Private version
defp calculate_level_from_xp(xp) do
  # implementation
end

# Public wrapper for external use
def calculate_user_level_from_xp(xp) do
  calculate_level_from_xp(xp)
end
```

**Pattern**: Keep core logic private, expose public wrapper when external access needed.

## Statistics Aggregation

```elixir
def get_user_stats(user_id) do
  user_level = Repo.get_by(UserLevel, user_id: user_id) ||
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

  completion_rate =
    if total_goals > 0 do
      Float.round(completed_goals / total_goals * 100, 1)
    else
      0.0
    end

  %{
    level: user_level.level,
    level_name: user_level.level_name,
    xp: user_level.xp,
    next_level_xp: get_next_level_xp(user_level.level),
    total_goals: total_goals,
    completed_goals: completed_goals,
    completion_rate: completion_rate,
    current_streak: calculate_current_streak(user_id),
    longest_streak: calculate_longest_streak(user_id)
  }
end
```

**Pattern**: Return comprehensive statistics as a map with computed fields.
