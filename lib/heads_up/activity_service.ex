defmodule HeadsUp.ActivityService do
  alias HeadsUp.{Repo, UserActivity, UserLevel, Users}
  import Ecto.Query

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

  def track_activity(user_id, activity_type, opts \\ []) do
    xp_change = Map.get(@xp_rewards, activity_type, 0)

    activity_attrs = %{
      user_id: user_id,
      activity_type: activity_type,
      xp_change: xp_change,
      description: Keyword.get(opts, :description),
      goal_id: Keyword.get(opts, :goal_id),
      post_id: Keyword.get(opts, :post_id),
      challenge_id: Keyword.get(opts, :challenge_id),
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

  defp calculate_level_from_xp(xp) do
    Enum.find(@level_thresholds, fn {_level, {min_xp, max_xp, _name}} ->
      xp >= min_xp and xp < max_xp
    end)
    |> case do
      {level, {_min, _max, name}} -> {level, name}
      nil -> {40, "Legendary Shark"}
    end
  end

  def get_level_info(level) do
    Map.get(@level_thresholds, level, {0, 100, "Seastar"})
  end

  def get_current_user_level(user_id) do
    user = Repo.get!(Users, user_id)
    current_xp = user.xp || 0

    # If user has no level stored or it's incorrect, calculate it
    if user.level do
      user.level
    else
      {level, _level_name} = calculate_level_from_xp(current_xp)

      # Update user with calculated level
      user
      |> Users.changeset(%{level: level})
      |> Repo.update!()

      level
    end
  end

  # Public version of calculate_level_from_xp for external use
  def calculate_user_level_from_xp(xp) do
    calculate_level_from_xp(xp)
  end

  def get_user_activity_summary(user_id, days \\ 30) do
    start_date = DateTime.utc_now() |> DateTime.add(-days * 24 * 60 * 60, :second)

    activities =
      from(a in UserActivity,
        where: a.user_id == ^user_id and a.inserted_at >= ^start_date,
        order_by: [desc: a.inserted_at]
      )
      |> Repo.all()

    total_xp = Enum.sum(Enum.map(activities, & &1.xp_change))
    activity_count = length(activities)

    %{
      total_xp: total_xp,
      activity_count: activity_count,
      activities: activities
    }
  end

  def get_daily_activity_chart_data(user_id, days \\ 365) do
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -days)

    activities =
      from(a in UserActivity,
        where: a.user_id == ^user_id and fragment("DATE(?)", a.inserted_at) >= ^start_date,
        select: {fragment("DATE(?)", a.inserted_at), count(a.id)},
        group_by: fragment("DATE(?)", a.inserted_at)
      )
      |> Repo.all()
      |> Map.new()

    # Generate data for each day
    for i <- 0..(days - 1) do
      date = Date.add(start_date, i)
      activity_count = Map.get(activities, date, 0)

      {date, activity_count}
    end
  end

  def get_user_activities(user_id, page, limit) do
    offset = (page - 1) * limit

    from(a in UserActivity,
      where: a.user_id == ^user_id,
      order_by: [desc: a.inserted_at],
      limit: ^limit,
      offset: ^offset,
      preload: [:user, :goal, :post]
    )
    |> Repo.all()
  end

  def get_user_stats(user_id) do
    # Get user level info
    user_level =
      Repo.get_by(UserLevel, user_id: user_id) ||
        %UserLevel{level: 1, xp: 0, level_name: "Seastar"}

    # Get various statistics
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

    total_posts =
      from(a in UserActivity,
        where: a.user_id == ^user_id and a.activity_type == "post_created",
        select: count(a.id)
      )
      |> Repo.one()

    total_likes_given =
      from(a in UserActivity,
        where: a.user_id == ^user_id and a.activity_type == "like_given",
        select: count(a.id)
      )
      |> Repo.one()

    total_likes_received =
      from(a in UserActivity,
        where: a.user_id == ^user_id and a.activity_type == "like_received",
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

    # Get current streak (consecutive days with activity)
    current_streak = calculate_current_streak(user_id)

    # Get longest streak
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
      # Count consecutive days with activity
      count_consecutive_days(activity_dates, today, 0)
    end
  end

  defp calculate_longest_streak(user_id) do
    # Get all dates with activity
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

  defp count_consecutive_days([], _current_date, count), do: count

  defp count_consecutive_days([date | rest], current_date, count) do
    if Date.diff(current_date, date) == count do
      count_consecutive_days(rest, current_date, count + 1)
    else
      count
    end
  end

  defp find_longest_consecutive_sequence([]), do: 0

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

  defp get_next_level_xp(current_level) do
    case Map.get(@level_thresholds, current_level + 1) do
      {min_xp, _max_xp, _name} -> min_xp
      # Max level reached
      nil -> nil
    end
  end
end
