# Gamification Patterns - Domain Documentation

## Overview

HeadsUp implements a gamification system with XP rewards, an ocean-themed level progression (40 levels from Seastar to Legendary Shark), activity tracking, and commitment charts (GitHub-style activity visualization).

## Gamification Files

| File | Purpose |
|------|---------|
| `/lib/heads_up/activity_service.ex` | XP rewards, level calculation, activity tracking |
| `/lib/heads_up/feed_service.ex` | Commitment chart data, feed generation |
| `/lib/heads_up/user_activity.ex` | Activity schema |
| `/lib/heads_up/user_level.ex` | User level schema |
| `/lib/heads_up_web/components/commitment_chart.ex` | Activity visualization component |

## Level System

### Level Thresholds

The system has 40 levels with ocean-themed names:

```elixir
# File: /lib/heads_up/activity_service.ex
@level_thresholds %{
  1 => {0, 100, "Seastar"},
  2 => {100, 250, "Seastar"},
  3 => {250, 400, "Seastar"},
  4 => {400, 600, "Seastar"},
  5 => {600, 850, "Seastar"},
  6 => {850, 1150, "Hermit Crab"},
  7 => {1150, 1500, "Hermit Crab"},
  8 => {1500, 1900, "Hermit Crab"},
  9 => {1900, 2350, "Hermit Crab"},
  10 => {2350, 2850, "Hermit Crab"},
  11 => {2850, 3400, "Sea Urchin"},
  12 => {3400, 4000, "Sea Urchin"},
  13 => {4000, 4650, "Sea Urchin"},
  14 => {4650, 5350, "Sea Urchin"},
  15 => {5350, 6100, "Sea Urchin"},
  16 => {6100, 6900, "Jellyfish"},
  17 => {6900, 7750, "Jellyfish"},
  18 => {7750, 8650, "Jellyfish"},
  19 => {8650, 9600, "Jellyfish"},
  20 => {9600, 10600, "Jellyfish"},
  21 => {10600, 11650, "Dolphin"},
  22 => {11650, 12750, "Dolphin"},
  23 => {12750, 13900, "Dolphin"},
  24 => {13900, 15100, "Dolphin"},
  25 => {15100, 16350, "Dolphin"},
  26 => {16350, 17650, "Octopus"},
  27 => {17650, 19000, "Octopus"},
  28 => {19000, 20400, "Octopus"},
  29 => {20400, 21850, "Octopus"},
  30 => {21850, 23350, "Octopus"},
  31 => {23350, 24900, "Whale"},
  32 => {24900, 26500, "Whale"},
  33 => {26500, 28150, "Whale"},
  34 => {28150, 29850, "Whale"},
  35 => {29850, 31600, "Whale"},
  36 => {31600, 33400, "Shark"},
  37 => {33400, 35250, "Shark"},
  38 => {35250, 37150, "Shark"},
  39 => {37150, 39100, "Shark"},
  40 => {39100, 999_999, "Legendary Shark"}
}
```

### Level Progression

| Levels | XP Range | Title |
|--------|----------|-------|
| 1-5 | 0-850 | Seastar |
| 6-10 | 850-2850 | Hermit Crab |
| 11-15 | 2850-6100 | Sea Urchin |
| 16-20 | 6100-10600 | Jellyfish |
| 21-25 | 10600-16350 | Dolphin |
| 26-30 | 16350-23350 | Octopus |
| 31-35 | 23350-31600 | Whale |
| 36-40 | 31600+ | Shark/Legendary Shark |

## XP Reward System

### XP Values

```elixir
# File: /lib/heads_up/activity_service.ex
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

### XP Categories

| Category | Activities | XP Range |
|----------|------------|----------|
| Goal Creation | goal_created | +50 |
| Goal Completion | goal_completed | +1000 |
| Goal Penalties | goal_failed, goal_frozen, goal_deleted | -200, -50, -100 |
| Posts | post_created | +25 |
| Social | likes, follows, friend requests | +2 to +10 |
| Daily | daily_login | +5 |
| Steps | goal_step_completed | +15 |

## Activity Tracking

### Track Activity Function

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

### Usage in Contexts

```elixir
# File: /lib/heads_up/goals.ex
def create_goal(attrs \\ %{}) do
  result =
    %Goal{}
    |> Goal.changeset(attrs)
    |> Repo.insert()

  case result do
    {:ok, goal} ->
      ActivityService.track_activity(goal.user_id, "goal_created",
        goal_id: goal.id,
        description: "Created goal: #{goal.title}"
      )
      {:ok, goal}

    error ->
      error
  end
end

def like_post(post_id, user_id) do
  post = Repo.get!(GoalPost, post_id) |> Repo.preload(:user)

  if post.user_id == user_id do
    {:error, :cannot_like_own_post}
  else
    result =
      %GoalPostLike{}
      |> GoalPostLike.changeset(%{goal_post_id: post_id, user_id: user_id})
      |> Repo.insert()

    case result do
      {:ok, like} ->
        # Track activity for the liker
        ActivityService.track_activity(user_id, "post_liked",
          post_id: post_id,
          like_id: like.id,
          description: "Liked a post"
        )

        # Track activity for the post owner (received like)
        ActivityService.track_activity(post.user_id, "post_received_like",
          post_id: post_id,
          like_id: like.id,
          description: "Received a like on post"
        )

        {:ok, like}

      error ->
        error
    end
  end
end
```

## Level Calculation

### Calculate Level from XP

```elixir
# File: /lib/heads_up/activity_service.ex
defp calculate_level_from_xp(xp) do
  Enum.find(@level_thresholds, fn {_level, {min_xp, max_xp, _name}} ->
    xp >= min_xp and xp < max_xp
  end)
  |> case do
    {level, {_min, _max, name}} -> {level, name}
    nil -> {40, "Legendary Shark"}
  end
end

# Public version for external use
def calculate_user_level_from_xp(xp) do
  calculate_level_from_xp(xp)
end
```

### Update User XP and Level

```elixir
# File: /lib/heads_up/activity_service.ex
def update_user_xp_and_level(user_id, xp_change) do
  user = Repo.get!(Users, user_id)
  current_xp = user.xp || 0
  new_xp = max(0, current_xp + xp_change)  # XP cannot go negative

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
```

## User Statistics

### Get User Stats

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

## Streak Calculation

### Current Streak

```elixir
# File: /lib/heads_up/activity_service.ex
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

### Longest Streak

```elixir
# File: /lib/heads_up/activity_service.ex
defp calculate_longest_streak(user_id) do
  activity_dates =
    from(a in UserActivity,
      where: a.user_id == ^user_id,
      select: fragment("DATE(?)", a.inserted_at),
      distinct: true,
      order_by: [asc: fragment("DATE(?)", a.inserted_at)]
    )
    |> Repo.all()

  if Enum.empty?(activity_dates) do
    0
  else
    find_longest_consecutive_sequence(activity_dates)
  end
end

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

## Commitment Chart Data

### Generate Chart Data

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

### Activity Intensity for Chart

```elixir
# File: /lib/heads_up/feed_service.ex
def get_user_activities_for_chart(user_id, days \\ 365) do
  end_date = Date.utc_today()
  start_date = Date.add(end_date, -days)

  activities =
    from(a in UserActivity,
      where: a.user_id == ^user_id and fragment("DATE(?)", a.inserted_at) >= ^start_date,
      select: {fragment("DATE(?)", a.inserted_at), count(a.id), sum(a.xp_change)},
      group_by: fragment("DATE(?)", a.inserted_at)
    )
    |> Repo.all()
    |> Enum.into(%{})

  for i <- 0..(days - 1) do
    date = Date.add(start_date, i)

    {activity_count, xp_total} =
      case Map.get(activities, date) do
        {count, xp} when not is_nil(count) -> {count, xp || 0}
        _ -> {0, 0}
      end

    %{
      date: date,
      activity_count: activity_count,
      xp_total: xp_total,
      intensity: calculate_intensity(activity_count)
    }
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

## Activity Types

```elixir
# File: /lib/heads_up/user_activity.ex
@activity_types [
  "goal_created",
  "goal_completed",
  "goal_failed",
  "goal_frozen",
  "goal_deleted",
  "goal_updated",
  "post_created",
  "post_liked",
  "post_received_like",
  "user_followed",
  "user_received_follow",
  "friend_request_sent",
  "friend_request_accepted",
  "daily_login",
  "goal_step_completed"
]
```

## Architectural Constraints

1. **Activity Tracking**: All significant actions call `ActivityService.track_activity`
2. **XP Rewards**: XP values defined in `@xp_rewards` module attribute
3. **Level Thresholds**: Level progression via `@level_thresholds` map
4. **Transactional**: XP updates wrapped in `Repo.transaction`
5. **Positive and Negative XP**: XP can be negative (failures, deletions)
6. **Streak Calculation**: Streaks calculated from activity dates dynamically
7. **Level Sync**: User level always derived from XP, kept in sync
