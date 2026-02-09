defmodule HeadsUp.FeedService do
  alias HeadsUp.{Repo, UserActivity, Users, UserFollow, Friendship}
  import Ecto.Query

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

    # Include current user's own activities
    all_user_ids = [user_id | feed_user_ids]

    # Get activities from followed users and friends
    # Fetch more than needed to account for privacy filtering
    fetch_limit = limit + 10

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
            "goal_updated",
            "goal_step_completed",
            "post_created",
            "post_liked",
            "challenge_created",
            "challenge_started",
            "challenge_completed",
            "challenge_failed",
            "challenge_shared",
            "challenge_joined",
            "daily_check_in_submitted",
            "user_followed",
            "friend_request_accepted"
          ],
        order_by: [desc: a.inserted_at],
        limit: ^fetch_limit,
        offset: ^offset,
        preload: [:user, :goal, :post, :challenge],
        select: a
      )
      |> Repo.all()

    # Filter by privacy — hide private/friends-only content from non-authorized users
    friend_id_set = MapSet.new(friend_ids)

    activities
    |> Enum.filter(fn activity ->
      cond do
        # Own activities always visible
        activity.user_id == user_id ->
          true

        # Goal-related: check goal privacy
        activity.goal_id && activity.goal ->
          case activity.goal.privacy do
            :public -> true
            :friends -> MapSet.member?(friend_id_set, activity.goal.user_id)
            :private -> false
            _ -> true
          end

        # Challenge-related: check challenge visibility
        activity.challenge_id && activity.challenge ->
          case activity.challenge.visibility do
            :public -> true
            :friends -> MapSet.member?(friend_id_set, activity.challenge.creator_user_id)
            :private -> false
            _ -> true
          end

        # Non-goal/non-challenge activities (follows, friend accepts) always visible
        true ->
          true
      end
    end)
    |> Enum.take(limit)
    |> Enum.map(&format_activity_for_feed/1)
  end

  def get_user_feed(user_id, page, limit) do
    offset = (page - 1) * limit
    get_user_feed(user_id, limit: limit, offset: offset)
  end

  def get_commitment_chart_data(user_id, year) do
    # Get all activities for the user in the given year
    start_date = Date.new!(year, 1, 1)
    end_date = Date.new!(year, 12, 31)

    daily_data =
      from(a in UserActivity,
        where: a.user_id == ^user_id,
        where: fragment("DATE(?)", a.inserted_at) >= ^start_date,
        where: fragment("DATE(?)", a.inserted_at) <= ^end_date,
        group_by: fragment("DATE(?)", a.inserted_at),
        select: %{
          date: fragment("DATE(?)", a.inserted_at),
          total_xp: sum(a.xp_change),
          activity_count: count(a.id)
        }
      )
      |> Repo.all()
      |> Enum.map(fn %{date: date, total_xp: total_xp, activity_count: activity_count} ->
        total_xp = total_xp || 0

        %{
          date: date,
          total_xp: total_xp,
          intensity: calculate_xp_intensity(total_xp),
          activity_count: activity_count
        }
      end)

    # Fill in missing dates with 0 activity
    fill_missing_dates(daily_data, start_date, end_date)
  end

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
      |> Map.new(fn {date, count, xp} -> {date, {count, xp}} end)

    # Generate chart data for each day
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

  defp calculate_xp_intensity(xp) do
    cond do
      # Very high
      xp >= 500 -> 4
      # High
      xp >= 200 -> 3
      # Medium
      xp >= 50 -> 2
      # Low
      xp > 0 -> 1
      # None
      true -> 0
    end
  end

  defp format_activity_for_feed(activity) do
    challenge = if Map.has_key?(activity, :challenge), do: activity.challenge, else: nil

    base_data = %{
      id: activity.id,
      user: activity.user,
      activity_type: activity.activity_type,
      description: activity.description,
      xp_change: activity.xp_change,
      inserted_at: activity.inserted_at,
      goal: activity.goal,
      post: activity.post,
      challenge: challenge
    }

    # Generate user-friendly description
    goal_title = if activity.goal, do: activity.goal.title, else: nil
    challenge_title = if challenge, do: challenge.title, else: nil

    user_friendly_description =
      case activity.activity_type do
        "goal_created" ->
          if goal_title, do: "created a new goal: \"#{goal_title}\"", else: "created a new goal"

        "goal_completed" ->
          if goal_title, do: "completed their goal: \"#{goal_title}\"", else: "completed a goal"

        "goal_failed" ->
          if goal_title, do: "failed their goal: \"#{goal_title}\"", else: "failed a goal"

        "goal_updated" ->
          if goal_title, do: "updated their goal: \"#{goal_title}\"", else: "updated a goal"

        "goal_step_completed" ->
          if goal_title,
            do: "completed a step in \"#{goal_title}\"",
            else: "completed a goal step"

        "post_created" ->
          if activity.post && goal_title do
            "posted an update in \"#{goal_title}\""
          else
            "created a new post"
          end

        "post_liked" ->
          if goal_title, do: "liked a post in \"#{goal_title}\"", else: "liked a post"

        "challenge_created" ->
          if challenge_title,
            do: "created a new challenge: \"#{challenge_title}\"",
            else: "created a new challenge"

        "challenge_started" ->
          if challenge_title,
            do: "started a challenge: \"#{challenge_title}\"",
            else: "started a challenge"

        "challenge_completed" ->
          if challenge_title,
            do: "completed the challenge: \"#{challenge_title}\"",
            else: "completed a challenge"

        "challenge_failed" ->
          if challenge_title,
            do: "failed the challenge: \"#{challenge_title}\"",
            else: "failed a challenge"

        "challenge_shared" ->
          if challenge_title,
            do: "shared \"#{challenge_title}\" as a template",
            else: "shared a challenge as template"

        "challenge_joined" ->
          if challenge_title,
            do: "joined the challenge: \"#{challenge_title}\"",
            else: "joined a challenge"

        "daily_check_in_submitted" ->
          activity.description || "submitted a daily check-in"

        "user_followed" ->
          "started following someone new"

        "friend_request_accepted" ->
          "made a new friend"

        _ ->
          activity.description || String.replace(activity.activity_type, "_", " ")
      end

    Map.put(base_data, :user_friendly_description, user_friendly_description)
  end

  defp fill_missing_dates(daily_data, start_date, end_date) do
    data_map = Map.new(daily_data, fn item -> {item.date, item} end)

    start_date
    |> Date.range(end_date)
    |> Enum.map(fn date ->
      Map.get(data_map, date, %{
        date: date,
        total_xp: 0,
        intensity: 0,
        activity_count: 0
      })
    end)
  end

  def get_trending_activities(limit \\ 10) do
    # Get popular activities from the last 7 days
    seven_days_ago = DateTime.utc_now() |> DateTime.add(-7 * 24 * 60 * 60, :second)

    from(a in UserActivity,
      join: u in Users,
      on: a.user_id == u.id,
      where: a.inserted_at >= ^seven_days_ago,
      where:
        a.activity_type in [
          "goal_created",
          "goal_completed",
          "post_created",
          "challenge_created",
          "challenge_completed"
        ],
      group_by: [a.goal_id, a.challenge_id, a.activity_type],
      having: count(a.id) > 1,
      order_by: [desc: count(a.id)],
      limit: ^limit,
      preload: [:user, :goal, :post, :challenge],
      select: a
    )
    |> Repo.all()
    |> Enum.map(&format_activity_for_feed/1)
  end
end
